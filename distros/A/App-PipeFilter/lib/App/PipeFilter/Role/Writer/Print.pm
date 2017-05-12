package App::PipeFilter::Role::Writer::Print;
{
  $App::PipeFilter::Role::Writer::Print::VERSION = '0.005';
}

use Moose::Role;

sub write_output {
  print { $_[1] } @_[2..$#_];
}

1;

__END__

# vim: ts=2 sw=2 expandtab
