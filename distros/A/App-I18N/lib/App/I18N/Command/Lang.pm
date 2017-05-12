package App::I18N::Command::Lang;
use warnings;
use strict;
use Cwd;
use App::I18N::Config;
use App::I18N::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use base qw(App::I18N::Command);


=head1 NAME

Lang - create new langauge

=head1 USAGE

    --mo        generate mo file

    --locale    create new po file from pot file in locale directory structure:
                    {podir}/{lang}/LC_MESSAGES/{potname}.po
                this will enable --mo option


    -q
    --quiet     just be quiet

    --podir=[path]
                po directory. potfile will be generated in {podir}/{appname}.pot

=cut

sub options { (
    'q|quiet'  => 'quiet',
    'locale'   => 'locale',
    'mo'       => 'mo',   # generate mo file
    'podir=s'  => 'podir',
    ) }


sub copy_potfile {
    my ( $self, $potfile, $pofile ) = @_;
    use File::Copy;

    $self->logger->info(  "$pofile created.");
    copy( $potfile , $pofile );
    if( $self->{mo} ) {
        my $mofile = $pofile;
        $mofile =~ s{\.po$}{.mo};
        $self->logger->info( "Generating MO file: $mofile" );
        system(qq{msgfmt -v $pofile -o $mofile});
    }
}

sub run {
    my ( $self, @langs ) = @_;
    my $logger = $self->logger();

    my $podir = $self->{podir};
    $podir = App::I18N->guess_podir( $self ) unless $podir;
    $self->{mo} = 1 if $self->{locale};

    mkpath [ $podir ];

    my $pot_name = App::I18N->pot_name;

    my $potfile = File::Spec->catfile( $podir, $pot_name . ".pot") ;
    if( ! -e $potfile ) {
        $logger->info( "$potfile not found." );
        return;
    }

    $logger->info( "$potfile found." );
    my $pofile;
    if( $self->{locale} ) {
        for my $lang ( @langs ) {
            mkpath [ File::Spec->join( $podir , $lang , 'LC_MESSAGES' )  ];
            $pofile = File::Spec->join( $podir , $lang , 'LC_MESSAGES' , $pot_name . ".po" );
            $self->copy_potfile( $potfile , $pofile );
        }
    }
    else {
        for my $lang ( @langs ) {
            $pofile = File::Spec->join( $podir , $lang . ".po" );
            $self->copy_potfile( $potfile , $pofile );
        }
    }
    $logger->info( "Done" );
}

1;
