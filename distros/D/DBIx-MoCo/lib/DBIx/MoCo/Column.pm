package DBIx::MoCo::Column;
use strict;
use Carp;

sub new {
    my $class = shift;
    my $self = shift || ''; # scalar
    bless \$self, $class;
}

1;

=head1 NAME

DBIx::MoCo::Column - Scalar blessed class for inflating columns.

=head1 SYNOPSIS

Inflate column value by using DBIx::MoCo::Column::* plugins.
If you set up your plugin like this,

  package DBIx::MoCo::Column::URI;

  sub URI {
    my $self = shift;
    return URI->new($$self);
  }

  sub URI_as_string {
    my $class = shift;
    my $uri = shift or return;
    return $uri->as_string;
  }

  1;

Then, you can use column_as_MyColumn method as following,

  my $e = MyEntry->retrieve(..);
  print $e->uri; # 'http://test.com/test'
  print $e->uri_as_URI->host; # 'test.com';

  my $uri = URI->new('http://www.test.com/test');
  $e->uri_as_URI($uri); # set uri by using URI instance

The name of infrate method which will be imported must be same as the package name.

If you don't define "as string" method (such as URI_as_string), 
scalar evaluated value of given argument will be used for new value instead.

=head1 SEE ALSO

L<DBIx::MoCo>, L<DBIx::MoCo::Column::URI>

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
