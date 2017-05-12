#
# This file is part of Action-Retry
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Action::Retry::Strategy::Constant;
{
  $Action::Retry::Strategy::Constant::VERSION = '0.24';
}

# ABSTRACT: Constant sleep time strategy

use Moo;


with 'Action::Retry::Strategy';
with 'Action::Retry::Strategy::HelperRole::RetriesLimit';


has sleep_time => (
    is => 'ro',
    lazy => 1,
    default => sub { 1000 },
);

sub compute_sleep_time { $_[0]->sleep_time }

sub reset { return }

sub next_step { return }

sub needs_to_retry { 1 }

# Inherited from Action::Retry::Strategy::HelperRole::RetriesLimit


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Action::Retry::Strategy::Constant - Constant sleep time strategy

=head1 VERSION

version 0.24

=head1 SYNOPSIS

To be used as strategy in L<Action::Retry>

=head1 ATTRIBUTES

=head2 sleep_time

  ro, Int, defaults to 1000 ( 1 second )

The number of milliseconds to wait between retries

=head2 max_retries_number

  ro, Int|Undef, defaults to 10

The number of times we should retry before giving up. If set to undef, never
stop retrying

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
