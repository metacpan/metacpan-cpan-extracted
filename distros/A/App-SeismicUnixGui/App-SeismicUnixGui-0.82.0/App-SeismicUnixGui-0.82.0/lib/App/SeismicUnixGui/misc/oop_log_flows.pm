package App::SeismicUnixGui::misc::oop_log_flows;
use Moose;
our $VERSION = '0.0.1';

=head2 Default  lines for   

 logging flows 
 Time::Piece is a core module that
 provides localtime

=cut

my @log_flows;
my $time = localtime;

$log_flows[0] =

 ( "\t" .'my $time = localtime;'. "\n".			
  "\t" . '$log->file(time);'. "\n".
  "\t" . '$log->file($flow[1]);' . "\n\n") ;

sub section {
    my ($self) = @_;
    return ( \@log_flows );
}

1;
