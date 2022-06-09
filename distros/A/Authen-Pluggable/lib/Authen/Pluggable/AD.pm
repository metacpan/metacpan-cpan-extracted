package Authen::Pluggable::AD;
$Authen::Pluggable::AD::VERSION = '0.03';
use Mojo::Base -base, -signatures;
use Net::LDAP;

has 'parent' => undef, weak => 1;
has _cfg => sub {
    return {
        server          => '127.0.0.1:389',
        managerDN       => 'CN=Administrator,CN=Users,DC=yourdomain,DC=local',
        managerPassword => 'YourSecretPassword',
        searchBase      => 'CN=Users,DC=yourdomain,DC=local',
        usernameAttribute => 'saMAccountName',
    };
};

sub authen ( $s, $user, $pass ) {
    my $ad = Net::LDAP->new( $s->_cfg->{server}, timeout => 5 )
        or do {
        $s->log( 'error',
            "Could not connect to ldap server "
                . $s->_cfg->{server}
                . ": $@" );
        return undef;
        };

    my $msg = $ad->bind( $s->_cfg->{managerDN},
        password => $s->_cfg->{managerPassword} );

    unless ($msg) {
        $s->log( 'error', "Wrong Manager DN or password" );
        return undef;
    }

    my $orig  = $user;
    my $extra = $user =~ tr/a-zA-Z0-9@._-//dc;
    $s->log( 'warn', "Invalid username '$orig', turned in $user" )
        if $extra;

    my $results = $ad->search(
        base   => $s->_cfg->{searchBase},
        filter => $s->_cfg->{usernameAttribute} . "=$user",
        attrs  => [ 'distinguishedName', 'mail', 'cn' ]
    );

    my $res_count = $results->count;
    return undef if ( $res_count == 0 );

    my $dn = $results->entry(0)->get_value("DistinguishedName");
    $msg = $ad->bind( $dn, password => $pass );
    $s->log( 'debug', "AD returned " . $msg->code . " : " . $msg->error );
    return undef if ( $msg->code != 0 );

    my $ret = { user => $user };

    for ( my $i = 0; $i < $res_count; $i++ ) {
        my $entry = $results->entry($i);
        foreach my $attr ( $entry->attributes ) {
            $ret->{$attr} = $entry->get_value($attr);
        }
    }

    #return { user => $user, cn => $cn, gid => $gid, uid => $uid };
    return $ret;
}

sub cfg ( $s, %cfg ) {
    if (%cfg) {
        while (my ($k, $v) = each %cfg) {
            $s->_cfg->{$k} = $v;
        }
    }
    return $s->parent;
}

sub log ( $s, $type, $msg ) {
    return unless $s->parent->log;
    $s->parent->log->$type($msg);
}

1;

=pod

=head1 NAME

Authen::Pluggable::AD - Authentication via Active Directory

=head1 VERSION

version 0.03

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Authentication via Active Directory
