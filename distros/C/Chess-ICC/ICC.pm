package Chess::ICC;

require 5.005_62;
use strict;
use warnings;

use Data::Dumper;
use HTML::TreeBuilder;
use LWP::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Chess::ICC ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';


# Preloaded methods go here.

sub games {
  my (undef, %cfg) = @_;
  my $url = "http://www.chessclub.com/finger/$cfg{of}";
  warn "querying $url";
  my $content = get $url;
  my $tree = HTML::TreeBuilder->new_from_content($content);
#  warn $tree;
  warn $content;
  my $h3 = $tree->look_down('_tag' => 'h3');
  my $table = $tree->look_down('_tag' => 'table');
  my @tr = $table->look_down('_tag' => 'tr');
  warn "we have ", scalar @tr, " rows";
#  warn Dumper($games);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Chess::ICC - manipulate the Internet Chess Club from the command line.

=head1 SYNOPSIS

  use Chess::ICC;

  my @game = Chess::ICC->games(of => 'princepawn');


=head1 DESCRIPTION

This is designed to allow one to pull one's game down in PGN format from the Internet Chess Club
immediately via the command-line. This is a complimentary means of doing so. Other options are to
have your games mailed to you (and wait on mail servers) or to do File/Save in your ICC interface
program. This is another way.

This is not quite yet done. One more day of HTML::TreeBuilder hacking should do it.

=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon <tbone@cpan.org>

=head1 SEE ALSO

HTML::TreeBuilder, LWP;

=cut
