package Acme::DateTime::Duration::Numeric;

use strict;
use 5.8.1;
our $VERSION = '0.03';

use overload '""' => \&value, '+0' => \&value, fallback => 1;
use DateTime;
use DateTime::Duration;

sub import {
    ## Should we do this for 'float' as well?
    overload::constant integer => sub { Acme::DateTime::Duration::Numeric->new(@_) };

    ## Gross hack to bypass DateTime's Params::Validate check
    $Params::Validate::NO_VALIDATION = 1;
}

sub new {
    my($class, $value) = @_;
    bless { value => $value }, $class;
}

sub value { $_[0]->{value} }

for my $accessor (qw( day hour minute month second week year )) {
    no strict 'refs';
    my $plural = $accessor . "s";
    *$accessor = *$plural = sub {
        my $self = shift;
        DateTime::Duration->new($plural => $self->{value});
    };
}

sub fortnight {
    my $self = shift;
    DateTime::Duration->new(weeks => 2 * $self->{value});
}

*fortnights = \&fortnight;

sub DateTime::Duration::ago {
    my $duration = shift;
    my $dt = $_[0] ? $_[0]->clone : DateTime->now;
    $dt->subtract_duration($duration);
}

*DateTime::Duration::until = \&DateTime::Duration::ago;

sub DateTime::Duration::from_now {
    my $duration = shift;
    my $dt = $_[0] ? $_[0]->clone : DateTime->now;
    $dt->add_duration($duration);
}

*DateTime::Duration::since = \&DateTime::Duration::from_now;

1;
__END__

=for stopwords DateTime ActiveSupport

=head1 NAME

Acme::DateTime::Duration::Numeric - ActiveSupport equivalent to Perl numeric variables

=head1 WARNING

This module is deprecated. Use L<autobox::DateTime::Duration> instead.

=head1 SYNOPSIS

  use Acme::DateTime::Duration::Numeric;

  # equivalent to DateTime::Duration->new(months => 1, days => 5);
  $duration = 1->month + 2->days;

  # equivalent to DateTime->now->add(years => 2);
  $datetime = 2->years->from_now;

  # equivalent to DateTime->now->add(months => 4, years => 5);
  $datetime = (4->months + 5->years)->from_now;

  # equivalent to DateTime->now->subtract(days => 3);
  $datetime = 3->days->ago;

=head1 DESCRIPTION

Acme::DateTime::Duration::Numeric is a module to add Time-related
methods to core integer values by using constant overloading. Inspired
by ActiveSupport (Rails) Core extensions to Numeric values.

=head1 BUGS

Using this module will turn off all Params::Validate validation since
I couldn't figure out how to make the object bypass its checks against
scalar data type in DateTime method calls.

Because it uses constant overloading, I'm not surprised there may be
other modules breaking when this module is in use.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<autobox::DateTime::Duration>

L<http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/Numeric/Time.html>

L<DateTime::Duration>, L<bigint>, L<overload>

=cut
