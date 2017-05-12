{
    package Ambrosia::Addons::Accessor;
    use strict;
    use warnings;

    use Ambrosia::Meta;

    class abstract
    {
        extends => [qw/Exporter/],
        public  => [qw/user/],
        private => [qw/authorize/],
    };

    our $VERSION = 0.010;

    our @EXPORT = qw/accessor/;

    our %PROCESS_MAP = ();
    our %ACCESSOR = ();

    sub import
    {
        my $pkg = shift;
        my %prm = @_;
        assign($prm{assign}) if $prm{assign};
    
        __PACKAGE__->export_to_level(1, @EXPORT);
    }

    sub assign
    {
        $PROCESS_MAP{$$} = shift;
    }

    {
        sub instance
        {
            my $package = shift;
            my $key = shift;
            return $ACCESSOR{$key} ||= $package->new(@_);
        }
    
        sub accessor
        {
            no warnings;
            return __PACKAGE__->instance($PROCESS_MAP{$$} || throw Ambrosia::error::Exception::BadUsage("First access to Ambrosia::Addons::Accessor without assign to access."), @_);
        }
    }

    sub authenticate
    {
        my $self = shift;
        my $login = shift;
        my $passwd = shift;
        my $level = shift;

        unless ( $level )
        {#Authorization is not required
            return new Ambrosia::Addons::Accessor::Result()->SET_PERMIT;
        }

        #If no username or password then prohibit
        return new Ambrosia::Addons::Accessor::Result()->SET_DENIED unless $login && $passwd;

        #check username and password
        return $self->check_password($login, $passwd, $level);
    }

    sub exit :Abstract
    {
    }

    sub remember_authorize_info :Abstract
    {
    }

    sub check_password
    {
        my $self = shift;
        my $login = shift || '';
        my $passwd = shift || '';
        my $level = shift;

        unless ( $self->user = $self->authorize->get($login, $level) )
        {
            return new Ambrosia::Addons::Accessor::Result()->SET_DENIED;
        }

        if ( $self->user->Password eq $passwd )
        {
            $self->remember_authorize_info($login, $passwd);
            return new Ambrosia::Addons::Accessor::Result()->SET_REDIRECT;
        }

        if ( crypt($self->user->Password, $passwd) eq $passwd )
        {
            return new Ambrosia::Addons::Accessor::Result()->SET_PERMIT;
        }

        return new Ambrosia::Addons::Accessor::Result()->SET_DENIED;
    }

    1;
}

{
    package Ambrosia::Addons::Accessor::Result;
    use strict;
    use warnings;

    our $VERSION = 0.010;

    use Ambrosia::Meta;
    use Ambrosia::Utils::Enumeration property => __state => PERMIT => 1, BAD_PASSWORD => 2, DENIED => 3, REDIRECT => 4;
    class sealed
    {
        private => [qw/__state/],
    };

    1;
}

__END__

=head1 NAME

Ambrosia::Addons::Accessor - 

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::Addons::Accessor;

=head1 DESCRIPTION

C<Ambrosia::Addons::Accessor> .

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
