package Apache::Singleton::Request;
$Apache::Singleton::Request::VERSION = '0.16';
# ABSTRACT: One instance per One Request

use strict;
use base 'Apache::Singleton';

BEGIN {
    use constant MP2 => $mod_perl::VERSION >= 1.99 ? 1 : 0;

    if (MP2) {
        require Apache2::RequestUtil;
    }
    else {
        require Apache;
    }
}

sub _get_instance {
    my $class = shift;
    my $r = MP2 ? Apache2::RequestUtil->request : Apache->request;
    my $key = "apache_singleton_$class";
    return $r->pnotes($key);
}

sub _set_instance {
    my($class, $instance) = @_;
    my $r = MP2 ? Apache2::RequestUtil->request : Apache->request;
    my $key = "apache_singleton_$class";
    $r->pnotes($key => $instance);
}

1;

__END__

=pod

=head1 NAME

Apache::Singleton::Request - One instance per One Request

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  # in httpd.conf
  PerlOptions +GlobalRequest

  # in your module (e.g.: Printer.pm)
  package Printer;
  use base qw(Apache::Singleton::Request);

=head1 DESCRIPTION

See L<Apache::Singleton>.

=head1 SEE ALSO

L<Apache::Singleton>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/apache-singleton>
and may be cloned from L<git://github.com/mschout/apache-singleton.git>

=head1 BUGS

Please report any bugs or feature requests to bug-apache-singleton@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Apache-Singleton

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
