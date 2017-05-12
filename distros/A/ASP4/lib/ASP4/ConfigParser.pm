
package
ASP4::ConfigParser;

use strict;
use warnings 'all';
use ASP4::Config;


sub new
{
  my ($class) = @_;
  
  return bless { }, $class;
}# end new()


sub parse
{
  my ($s, $doc, $root) = @_;
  
  my $config = ASP4::Config->new( $doc, $root );
  
  # Now do any post-processing:
  foreach my $class ( $config->system->post_processors )
  {
    (my $file = "$class.pm") =~ s/::/\//;
    require $file unless $INC{$file};
    $config = $class->new()->post_process( $config );
  }# end foreach()
  
  return $config;
}# end parse()

1;# return true:

