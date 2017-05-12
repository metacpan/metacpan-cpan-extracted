package App::vaporcalc::Exception;
$App::vaporcalc::Exception::VERSION = '0.005004';
use Defaults::Modern;

use Moo;
extends 'Throwable::Error';

1;

=pod

=head1 NAME

App::vaporcalc::Exception

=head1 SYNOPSIS

  use App::vaporcalc::Exception;
  App::vaporcalc::Exception->throw("died!")

=head1 DESCRIPTION

L<App::vaporcalc> exception objects.

A subclass of L<Throwable::Error>. Look there for details.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
