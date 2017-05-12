package Cache::Reddit::Bleach;
$Cache::Reddit::Bleach::VERSION = '0.04';
use warnings;
use strict;

sub wash
{
  local $_ = unpack "b*", pop; tr/01/ \t/;$_
}

sub dry
{
  local $_ = pop; tr/ \t/01/; pack "b*", $_
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cache::Reddit::Bleach

=head1 VERSION

version 0.04

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
