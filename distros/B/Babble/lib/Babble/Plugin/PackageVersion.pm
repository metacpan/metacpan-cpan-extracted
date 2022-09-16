package Babble::Plugin::PackageVersion;

use Moo;
use Data::Dumper;

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->each_match_within(PackageDeclaration => [
    [ name => q{
        package
            (?>(?&PerlNWS)) (?>(?&PerlQualifiedIdentifier))
    }],
    [ ws => q{
        (?>(?&PerlNWS))
    }],
    [ version => q{
        (?&PerlVersionNumber)
    }],
    q{
            (?>(?&PerlOWSOrEND))
    },
    [ rest => q[
            (?> ; | (?&PerlBlock) | (?= \} | \z ))
    ]],
  ] => sub {
    my ($m) = @_;
    my $gr = $m->grammar_regexp;

    my ($name, $ws, $version, $rest) =
      @{$m->submatches}{ qw(name ws version rest) };

    $ws->replace_text('');

    my $version_info = do {
      local $Data::Dumper::Terse = 1;
      local $Data::Dumper::Indent = 0;
      Dumper($version->text);
    };
    # not using line with $VERSION to avoid inaccurate VERSION detection
    my $version_statement = qq{our \044VERSION = }.$version_info.';';
    $version->replace_text('');

    if( $rest->text =~ /\A\{/ ) {
      $rest->transform_text(sub { s/\A \{ (?&PerlOWS) $gr/{\n${version_statement}\n/x });
    } else {
      $rest->transform_text(sub { s/\A ;? /;\n${version_statement}\n/x });
    }
  });
}

1;
__END__

=head1 NAME

Babble::Plugin::PackageVersion - Plugin for package version syntax

=head1 SYNOPSIS

Converts usage of the package version syntax from

    package NAMESPACE VERSION

to

    package NAMESPACE;
    $NAMESPACE::VERSION = VERSION;

=head1 SEE ALSO

L<package-version syntax|Syntax::Construct/package-version>

=cut
