#line 1 "inc/Module/Install/Metadata.pm - /usr/lang/perl/5.8.0/lib/site_perl/5.8.0/Module/Install/Metadata.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/Metadata.pm $ $Author: iain $
# $Revision: #18 $ $Change: 1537 $ $DateTime: 2003/05/20 22:50:53 $ vim: expandtab shiftwidth=4

package Module::Install::Metadata;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

$VERSION = '0.01';

use strict 'vars';
use vars qw($VERSION);

sub Meta { shift }

my @scalar_keys = qw(name version abstract author license distribution_type);
my @tuple_keys  = qw(build_requires requires recommends bundles);

foreach my $key (@scalar_keys) {
    *$key = sub {
        my $self = shift;
        return $self->{values}{$key} unless @_;
        $self->{values}{$key} = shift;
        return $self;
    };
}

foreach my $key (@tuple_keys) {
    *$key = sub {
        my ($self, $module, $version) = (@_, 0, 0);
        return $self->{values}{$key} unless $module;
        my $rv = [$module, $version];
        push @{$self->{values}{$key}}, $rv;
        return $rv;
    };
}

sub features {
    my $self = shift;
    while (my ($name, $mods) = splice(@_, 0, 2)) {
        push @{$self->{values}{features}}, ($name => [map { ref($_) ? @$_ : $_ } @$mods] );
    }
    return @{$self->{values}{features}};
}

sub _dump {
    my $self = shift;
    my $package = ref($self->_top);
    my $version = $self->_top->VERSION;
    my %values = %{$self->{values}};
    $values{distribution_type} ||= 'module';

    my $dump = '';
    foreach my $key (@scalar_keys) {
        $dump .= "$key: $values{$key}\n" if exists $values{$key};
    }
    foreach my $key (@tuple_keys) {
        next unless exists $values{$key};
        $dump .= "$key:\n";
        $dump .= "  $_->[0]: $_->[1]\n" for @{$values{$key}};
    }

    return($dump . "private:\n  directory:\n    - inc\ngenerated_by: $package version $version\n");
}

sub read {
    my $self = shift;
    $self->include( 'YAML' );
    require YAML;
    my $data = YAML::LoadFile( 'META.yml' );
    # Call methods explicitly in case user has already set some values.
    while ( my ($key, $value) = each %$data ) {
        next unless $self->can( $key );
        if (ref $value eq 'HASH') {
            while (my ($module, $version) = each %$value) {
                $self->$key( $module => $version );
            }
        }
        else {
            $self->$key( $value );
        }
    }
    return $self;
}

sub write {
    my $self = shift;
    return $self unless $self->admin;
    return if -f "META.yml";
    warn "Creating META.yml\n";
    open META, "> META.yml" or die $!;
    print META $self->_dump;
    close META;
    return $self;
}

sub version_from {
    my ($self, $version_from) = @_;
    require ExtUtils::MM_Unix;
    $self->version(ExtUtils::MM_Unix->parse_version($version_from));
}

1;
