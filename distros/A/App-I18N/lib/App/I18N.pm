package App::I18N;
use strict;
use warnings;
use Carp;
use File::Copy;
use File::Find::Rule;
use File::Path qw/mkpath/;
use Locale::Maketext::Extract;
use Getopt::Long;
use Exporter 'import';
use JSON::XS;
use YAML::XS;
use File::Basename;
use Locale::Maketext::Extract;
use App::I18N::Logger;
use Cwd;
use Encode;
use File::Spec;
use MIME::Types ();
use constant USE_GETTEXT_STYLE => 1;


# our @EXPORT = qw(_);

our $VERSION = '0.034';
our $LOGGER;
our $LMExtract;
our $MIME = MIME::Types->new();

sub logger {
    $LOGGER ||= App::I18N::Logger->new;
    return $LOGGER;
}

Locale::Maketext::Lexicon::set_option( 'allow_empty' => 1 );
Locale::Maketext::Lexicon::set_option( 'use_fuzzy'   => 1 );
Locale::Maketext::Lexicon::set_option( 'encoding'    => "UTF-8" );
Locale::Maketext::Lexicon::set_option( 'style'       => 'gettext' );

sub lm_extract {
    return $LMExtract ||= Locale::Maketext::Extract->new(
        plugins => {
            'Locale::Maketext::Extract::Plugin::PPI' => [ 'pm','pl' ],
            'tt2' => [ ],
            # 'perl' => ['pl','pm','js','json'],
            'perl' => [ '*' ],   # _( ) , gettext( ) , loc( ) ...
            'mason' => [ ] ,
            'generic' => [ '*' ],
        },
        verbose => 1, warnings => 1 );
}

sub guess_appname {
    return lc(basename(getcwd()));
}

sub pot_name {
    my $self = shift;
    return guess_appname();
}


sub _check_mime_type {
    my $self       = shift;
    my $local_path = shift;
    my $mimeobj = $MIME->mimeTypeOf($local_path);
    my $mime_type = ($mimeobj ? $mimeobj->type : "unknown");
    return if ( $mime_type =~ /^image/ );
    return if ( $mime_type =~ /compressed/ );  # ignore compressed archive files
    # return if ( $mime_type =~ /^application/ );
    return 1;
}

sub extract_messages {
    my ( $self, @dirs ) = @_;
    my @files = map { ( -d $_ ) ? File::Find::Rule->file->in($_) : $_ } @dirs;
    my $logger = $self->logger;
    my $lme = $self->lm_extract;
    foreach my $file (@files) {
        next if $file =~ m{(^|/)[\._]svn/};
        next if $file =~ m{\~$};
        next if $file =~ m{\.pod$};
        next if $file =~ m{^\.git};
        next unless $self->_check_mime_type($file);
        $logger->info("Extracting messages from '$file'");
        $lme->extract_file($file);
    }
}

sub update_catalog {
    my ( $self, $translation , $cmd ) = @_;

    $cmd ||= {};

    my $logger = $self->logger;
    $logger->info( "Updating message catalog '$translation'");

    my $lme = $self->lm_extract;
    $lme->read_po( $translation ) if -f $translation && $translation !~ m/pot$/;

    # Reset previously compiled entries before a new compilation
    $lme->set_compiled_entries;
    $lme->compile(USE_GETTEXT_STYLE);
    $lme->write_po($translation);

    # patch CHARSET
    $logger->info( "Set CHARSET to UTF-8" );
    open my $fh , "<" , $translation;
    my @lines = <$fh>;
    close $fh;

    open my $out_fh , ">" , $translation;
    for my $line ( @lines ) {
        $line =~ s{charset=CHARSET}{charset=UTF-8};
        print $out_fh $line;
    }
    close $out_fh;


    if( $cmd->{mo} ) {
        my $mofile = $translation;
        $mofile =~ s{\.po$}{.mo};
        $logger->info( "Generating MO file: $mofile" );
        system(qq{msgfmt -v $translation -o $mofile});
    }
}

sub guess_podir {
    my ($class,$cmd) = @_;
    my $podir;
    $podir = 'po' if -e 'po';
    $podir = 'locale' , $cmd->{locale} = 1 if -e 'locale';
    $podir ||= 'locale' if $cmd->{locale};
    $podir ||= 'po';
    return $podir;
}

sub get_po_path {
    my ( $self, $podir, $lang, $is_locale ) = @_;
    my $pot_name = App::I18N->pot_name;
    my $path;
    if ($is_locale) {
        $path = File::Spec->join( $podir, $lang . ".po" );
    }
    else {
        $path = File::Spec->join( $podir, 'locale', $lang, 'LC_MESSAGES', $pot_name . ".po" );
    }
    return $path;
}

sub update_catalogs {
    my ($self,$podir , $cmd ) = @_;
    my @catalogs = grep !m{(^|/)(?:\.svn|\.git)/}, 
                File::Find::Rule->file
                        ->name('*.po')->in( $podir);

    my $logger = App::I18N->logger;
    unless ( @catalogs ) {
        $logger->error("You have no existing message catalogs.");
        $logger->error("Run `po lang <lang>` to create a new one.");
        $logger->error("Read `po help` to get more info.");
        return 
    }

    foreach my $catalog (@catalogs) {
        $self->update_catalog( $catalog , $cmd );
    }
}



# _('Internationalization')
# _('Translate me')

1;
__END__
=head1 NAME

App::I18N - I18N utility.

=head1 DESCRIPTION

I18N management utility, provides an command-line interface to parse /
translate / update mo file i18n messages.

App::I18N borrows some good stuff from L<Jifty::I18N> and L<Jifty::Script::Po>
and tries to provide a general po management script for all frameworks |
applications.

=head1 USAGE

=head2 Basic flow

=head3 Basic po file manipulation:

parse strings from `lib` path:

    $ cd app
    $ po parse lib

this will generate:

    po/app.pot

please modify the CHARSET in po/app.pot.

    ... modify CHARSET ...

create new language file (po file):

    po lang en
    po lang fr
    po lang ja
    po lang zh_TW

this generates:

    po/en.po
    po/fr.po
    po/ja.po
    po/zh_TW.po

    ... do translation here

when you added more message in your application. you might need to update po
messages, but you dont have to delete/recreate these po files, you can just parse your messages again
all of your translations will be kept. eg:

    $ po parse lib

    ... do translation again ...

### Generate locale and mo file for php-gettext or anyother gettext i18n app:

parse strings from `.` path and use --locale (locale directory structure):

    $ cd app
    $ po parse --locale .

this will generate:
    
    po/app.pot

please modify the CHARSET in po/app.pot.

    ... modify CHARSET ...

create new language file (po file and mo file) in locale directory structure:

    $ po lang  --locale en
    $ po lang  --locale zh_TW

this will generate:

    po/en/LC_MESSAGES/app.po
    po/en/LC_MESSAGES/app.mo
    po/zh_TW/LC_MESSAGES/app.po
    po/zh_TW/LC_MESSAGES/app.mo

(you can use --podir option to generate those stuff to other directory)

    ... do translation here ...

if you use mo file , you might need to update mo file.

    $ po update --locale

eg:

    -project (master) % po update --mo --podir locale
        Updating locale/zh_TW/LC_MESSAGES/project.po
        Updating locale/zh_TW/LC_MESSAGES/project.mo
        9 translated messages, 53 untranslated messages.

Note that if you have `po` or `locale` directory exists, then it will be the default po directory.

And `locale` directory will enable `--locale` option.

## Show Translation Status

    $ po status

    Translation Status:
        en_US: [                                                  ]  0% (0/8) 
        zh_TW: [======                                            ] 12% (1/8) 


=head2 Auto Translation

Auto translate via Google Translate REST API:

Default backend is google translate REST API, This will translate zh\_TW.po file and translate msgid (en\_US)
to msgstr (zh\_TW):

    $ po auto zh_TW --from en_US

    $ po auto zh_CN --from en_US --to zh_CN

    $ po auto zh_CN --from en_US --overwrite --prompt

    $ po auto --backend google-rest --from en\_US --to zh\_TW

=cut
