package Datahub::Factory::Util;

use Datahub::Factory::Sane;

our $VERSION = '1.71';

use Exporter qw(import);
use Scalar::Util  ();
use Ref::Util     ();

our %EXPORT_TAGS = (
    misc => [qw(require_package)]
);

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

$EXPORT_TAGS{all} = \@EXPORT_OK;

# globtype Reference
*is_ref = \&Ref::Util::is_ref;

# globtype Reference
*is_glob_ref = \&Ref::Util::is_plain_globref;

# Output everything in UTF-8
binmode STDOUT, ":utf8";

sub is_value {
    defined($_[0]) && !is_ref($_[0]) && !is_glob_ref(\$_[0]);
}

sub is_string {
    is_value($_[0]) && length($_[0]) > 0;
}

sub is_invocant {
    my ($inv) = @_;
    if (ref $inv) {
        return !!Scalar::Util::blessed($inv);
    }
    else {
        return !!_get_stash($inv);
    }
}

sub is_instance {
    my $obj = shift;
    Scalar::Util::blessed($obj) || return 0;
    $obj->isa($_) || return 0 for @_;
    1;
}

sub require_package {
    my ($pkg, $ns) = @_;

    if ($ns) {
        unless ($pkg =~ s/^\+// || $pkg =~ /^$ns/) {
            $pkg = "${ns}::$pkg";
        }
    }

    return $pkg if is_invocant($pkg);

    eval "require $pkg;1;"
        or Catmandu::NoSuchPackage->throw(
        message      => "No such package: $pkg",
        package_name => $pkg
        );

    $pkg;
}

# the following code is taken from Data::Util::PurePerl 0.63
sub _get_stash {
    my ($inv) = @_;

    if (Scalar::Util::blessed($inv)) {
        no strict 'refs';
        return \%{ref($inv) . '::'};
    }
    elsif (!is_string($inv)) {
        return undef;
    }

    $inv =~ s/^:://;

    my $pack = *main::;
    for my $part (split /::/, $inv) {
        return undef unless $pack = $pack->{$part . '::'};
    }
    return *{$pack}{HASH};
}


1;

__END__
