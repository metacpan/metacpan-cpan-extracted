package Data::Localize::Util;
use strict;
use base qw(Exporter);
use Data::Localize;
our @EXPORT_OK = qw(_alias_and_deprecate);

sub _alias_and_deprecate($$) {
    my ($old, $new) = @_;

    my ($pkg) = caller();
    {
        no strict 'refs';
        my $code = \&{ $pkg . '::' . $new };
        if (Data::Localize::DEBUG()) {
            *{ $pkg . '::' . $old } = sub {
                local $Carp::CarpLevel = $Carp::CarpLevel + 1;
                Carp::cluck("Use of $old is deprecated. Please use $new instead");
                $code->(@_);
            };
        } else {
            *{$pkg . '::' . $old} = *{ $pkg . '::' . $new};
        }
    }
}

1;

__END__

=head1 NAME

Data::Localize::Util - Data::Localize Internal Utilities 

=head1 SYNOPSIS

    # Used internally

=cut
