package Data::Password::zxcvbn::AuthorTools::PackageWriter;
use v5.26;
use Types::Path::Tiny qw(Dir);
use Types::Common::String qw(NonEmptySimpleStr NonEmptyStr);
use Types::PerlVersion qw(PerlVersion);
use Types::Standard qw(Maybe);
use Data::Dumper qw(Dumper);
use Moo::Role;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: common role for tools that generate packages


has output_dir => (
    is => 'ro',
    default => $ARGV[1] || 'lib/',
    isa => Dir,
    coerce => 1,
);

has package_name => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    required => 1,
);

has package_version => (
    is => 'ro',
    defaul => $ARGV[0],
    isa => Maybe[PerlVersion],
    coerce => 1,
);

has package_abstract => (
    is => 'ro',
    isa => NonEmptyStr,
    required => 1,
);

has package_description => (
    is => 'ro',
    isa => NonEmptyStr,
    required => 1,
);

requires 'hash_variable_name';

sub write_out {
    my ($self, $hashref) = @_;

    my $data_str = Data::Dumper->new([$hashref])
        ->Indent(1)
        ->Trailingcomma(1)
        ->Purity(1)
        ->Useqq(0)
        ->Terse(1)
        ->Quotekeys(1)
        ->Sortkeys(1)
        ->Dump;
    $data_str =~ s[^\{][(];
    $data_str =~ s[\};?$][)];

    my $package_name = $self->package_name;

    my $file = $self->output_dir->child( ($package_name =~ s{::}{/}gr) . '.pm');
    my $dir = $file->parent;
    -d $dir or $file->parent->mkpath or die "failed to create output path $dir: $!";

    my $fh = $file->openw_utf8;

    print $fh <<"END";
package $package_name;
use strict;
use warnings;
END

    my $package_abstract = $self->package_abstract;
    my $package_description = $self->package_description;
    my $hash_variable_name = $self->hash_variable_name;

    if (my $version = $self->package_version) {
        print $fh <<"END";
our \$VERSION = '$version';

=head1 NAME

$package_name - $package_abstract

END
    }
    else {
        print $fh <<"END";
# VERSION
# ABSTRACT: $package_abstract

END
    }

    print $fh <<"EOF";
=head1 DESCRIPTION

$package_description

=cut

our %${hash_variable_name} = $data_str;

1;
EOF
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::AuthorTools::PackageWriter - common role for tools that generate packages

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

Internal role, you probably don't need to know about this.

=for Pod::Coverage output_dir package_name package_version
package_abstract package_description write_out

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
