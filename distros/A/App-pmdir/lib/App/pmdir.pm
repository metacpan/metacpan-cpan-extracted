package App::pmdir;
BEGIN {
  $App::pmdir::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: returns the directory of a specific Perl module
$App::pmdir::VERSION = '0.002';
use strict;
use warnings;
use Module::Runtime qw( require_module );
use File::Spec;

sub pmdir {
  my ( $module ) = @_;
  my $dir;
  eval {
    require_module($module);
    my $filename = $module;
    $filename =~ s!::!/!g;
    $filename .= '.pm';
    my $file = $INC{$filename};
    return undef unless $file;
    my @return = File::Spec->splitpath($file);
    $dir = $return[1];
  };
  return undef if $@ || !$dir;
  return $dir;
}

1;

__END__

=pod

=head1 NAME

App::pmdir - returns the directory of a specific Perl module

=head1 VERSION

version 0.002

=head1 DESCRIPTION

See L<pmdir>.

=head1 SUPPORT

IRC

  Join #sycontent on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  https://github.com/Getty/p5-app-pmdir
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Getty/p5-app-pmdir/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
