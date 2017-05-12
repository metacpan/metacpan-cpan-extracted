package App::I18N::Command::Update;
use warnings;
use strict;
use Cwd;
use App::I18N::Config;
use App::I18N::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use base qw(App::I18N::Command);

sub options { (
    'podir=s'  => 'podir',
    'mo'       => 'mo',   # generate mo file
    'locale'   => 'locale',
    ) }

sub run {
    my ( $self, $lang ) = @_;
    my $logger = App::I18N->logger();
    my $podir = $self->{podir};
    $podir = App::I18N->guess_podir( $self ) unless $podir;
    $self->{mo} = 1 if $self->{locale};

    my @pofiles = File::Find::Rule->file->name( "*.po" )->in( $podir );
    for my $pofile ( @pofiles ) {
        $logger->info( "Updating $pofile" );
        if( $self->{mo} ) {
            my $mofile = $pofile;
            $mofile =~ s{\.po$}{.mo};
            $logger->info( "Updating $mofile" );
            qx{msgfmt -v $pofile -o $mofile};
        }
    }
}



1;
__END__

=head1 NAME

App::I18N::Command::Update - update mo files

=head1 USAGE

if you use mo file , you might need to update mo file.

    $ po update --locale

eg:

    -project (master) % po update --mo --podir locale
        Updating locale/zh_TW/LC_MESSAGES/project.po
        Updating locale/zh_TW/LC_MESSAGES/project.mo
        9 translated messages, 53 untranslated messages.
=cut
