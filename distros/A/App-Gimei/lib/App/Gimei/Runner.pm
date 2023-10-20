package App::Gimei::Runner;

use warnings;
use v5.22;
binmode STDOUT, ":utf8";

use Getopt::Long;
use Pod::Usage;
use Pod::Find qw( pod_where );

use App::Gimei;

use Class::Tiny;

#
# global vars
#

my %conf = ( POD_FILE => pod_where( { -inc => 1 }, 'App::Gimei' ) );

#
# methods
#

sub parse_option {
    my ( $self, $args_ref, $opts_ref ) = @_;

    $opts_ref->{n}   = 1;
    $opts_ref->{sep} = ', ';

    my $p = Getopt::Long::Parser->new( config => ["no_ignore_case"], );

    local $SIG{__WARN__} = sub { die "Error: $_[0]" };
    my $ok = $p->getoptionsfromarray( $args_ref, $opts_ref, "help|h", "version|v", "n=i",
        "sep=s", );

    if ( $opts_ref->{n} < 1 ) {
        die
          "Error: value $opts_ref->{n} invalid for option n (must be positive number)\n";
    }
}

sub execute {
    my ( $self, @args ) = @_;

    my %opts;
    $self->parse_option( \@args, \%opts );

    if ( $opts{version} ) {
        say "$App::Gimei::VERSION";
        return 0;
    }

    if ( $opts{help} ) {
        pod2usage( -input => $conf{POD_FILE}, -exitval => 'noexit' );
        return 0;
    }

    if ( !@args ) {
        push @args, 'name:kanji';
    }

    my @generators = App::Gimei::Parser::parse_args( @args );
    
    semantic_analysis( @generators );

    foreach ( 1 .. $opts{n} ) {
	my ( @words, %cache );
	foreach my $g (@generators) {
	    push @words, $g->execute( \%cache );
	}
        say join $opts{sep}, @words;
    }

    return 0;
}

sub semantic_analysis {
    my ( @generators ) = @_;
    
    foreach my $gen (@generators) {
	if ($gen->word_class eq 'Data::Gimei::Address' && $gen->render eq 'romaji') {
	    die "Error: rendering romaji is not supported for address\n";
	}
    }
}

1;
