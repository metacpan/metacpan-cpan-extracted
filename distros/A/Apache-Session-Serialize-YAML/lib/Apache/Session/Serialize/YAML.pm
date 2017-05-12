package Apache::Session::Serialize::YAML;

use strict;
use vars qw($VERSION);
$VERSION = 0.02;

use YAML ();

sub serialize {
    my $session = shift;
    $session->{serialized} = YAML::Dump($session->{data});
}

sub unserialize {
    my $session = shift;
    $session->{data} = YAML::Load($session->{serialized});
}


1;
__END__

=head1 NAME

Apache::Session::Serialize::YAML - use YAML for serialization

=head1 SYNOPSIS

  use Apache::Session::Flex;

  tie %session, 'Apache::Session::Flex', $id, {
       Store     => 'MySQL',
       Lock      => 'Null',
       Generate  => 'MD5',
       Serialize => 'YAML',
  };


=head1 DESCRIPTION

Apache::Session::Serialize::YAML enables you to use YAML (YAML Ain't
Makeup Language [tm]) for Apache::Session serialization format. YAML
is a generic data serialization language for scripting languages, so
this module can be a good start to share session data with Ruby,
Python or PHP etc.

See http://www.yaml.org/ for details of YAML.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<YAML>, L<Apache::Session>, L<Apache::Session::PHP>

=cut
