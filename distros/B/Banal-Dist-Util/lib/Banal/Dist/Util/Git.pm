use 5.014;  # because we use the 'state' and  'non-destructive substitution' feature (s///r)
use strict;
use warnings;

package Banal::Dist::Util::Git;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: General purpose utility collection for <Dist::Zilla::*::Author::TABULO>
# KEYWORDS: author utility

our $VERSION = '0.005';
# AUTHORITY

use Path::Tiny;

use Exporter::Shiny qw(
  detect_settings_from_git
);

use namespace::autoclean;


# Detect settings (like remote 'server') from the local git repository
sub detect_settings_from_git {
  my  %args = @_;
  my  $dir  = $args{dir} || Path::Tiny->cwd;
  my  %detected;

  REMOTE: {
    eval {
      my  $git  = Git::Wrapper->new( $dir );
      my @lines  = $git->remote( {v=>1} );
      /^(\S+)\s+(\S+)\s+\(fetch\)$/i and $detected{remotes}{$1}=$2 foreach (@lines);
    };

    last REMOTE unless ( exists $detected{remotes} ) && ( exists $detected{remotes}{origin} );
    last REMOTE unless $detected{remotes}{origin} =~ qr{^ (https?|git):/(?<realm>.*)?/
                                            (?<domain> .* ) / (:? (?<folder> .*) /)? (?<repo> .*) \.git$}xi;
    my ($domain, $folder) = ( $+{domain}, $+{folder} );

    if ( $domain =~ /^((?<server>github)\.com) | ((?<server>bitbucket)\.org)$/xi) {
      my $server = $detected{server} = $+{server};
      $detected{"server_amr_opt_${server}"}= "user:${folder}";  # for [AutoMetaResources]
    } elsif ( $domain =~ /^git\.moose\.perl\.org$/xi ) {
      $detected{server} = 'gitmo';
    } elsif ( $domain =~ /^git\.shadowcat\.co\.uk$/xi ) {
      $detected{server} = $folder  if $folder =~ /^catagits|p5sagit|dbsrgits$/;
    }
  }
  wantarray ? (%detected) : \%detected;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Banal::Dist::Util::Git - General purpose utility collection for <Dist::Zilla::*::Author::TABULO>

=head1 VERSION

version 0.005

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Banal-Dist-Util>
(or L<bug-Banal-Dist-Util@rt.cpan.org|mailto:bug-Banal-Dist-Util@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
