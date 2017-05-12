package Couchbase::Client::Compat;
use strict;
use warnings;
use base qw(Couchbase::Client);
use Couchbase::Client::Errors;
use base qw(Exporter);

our @EXPORT_OK = qw(return_for_multi_wrap return_for_op);

#These errors are 'negative replies', all others are 'error' replies.
our %ErrorMap = (
    COUCHBASE_NOT_STORED, 0,
    COUCHBASE_KEY_EEXISTS, 0,
    COUCHBASE_KEY_ENOENT, 0,
    COUCHBASE_DELTA_BADVAL, 0,
    COUCHBASE_E2BIG, 0,
);

sub return_for_multi_wrap {
    my ($requests,$response,$op) = @_;
    
    if(wantarray) {
        #ugh, really?
        my @retvals;
        foreach my $req (@$requests) {
            my $key = ref $req eq 'ARRAY' ? $req->[0] : $req;
            my $retval = return_for_op($response->{$key}, $op);
            push @retvals, $retval;
        }
        return @retvals;
    } else {
        #scalar:
        while (my ($k,$v) = each %$response) {
            $response->{$k} = return_for_op($v, $op);
        }
        return $response;
    }
}

sub return_for_op {
    my ($retval, $op) = @_;    
    
    my $errval = $retval->errnum;
    
    if ($errval) {
        $errval = $ErrorMap{$errval};
    }
    
    if ($retval->errnum && (!defined $errval)) {
        # Fatal error:
        return undef;
    }
    
    if ($op =~ /^(?:get|incr|decr)$/) {
        return $retval->value;
    }
    
    if ($op eq 'gets') {
        return [$retval->cas, $retval->value];
    }
    
    if ($op =~ /^(?:set|cas|add|append|prepend|replace|remove|delete)/) {
        return int($retval->errnum == 0);
    }
    
}

sub new {
    my ($cls,$options) = @_;
    my $o = $cls->SUPER::new($options);
    bless $o, $cls;
    return $o;
}


foreach my $sub (qw(
                 get gets
                 set append prepend replace add
                 remove delete
                 incr decr cas)) {
    no strict 'refs';
    *{$sub} = sub {
        my $self = shift;
        my $ret = $self->${\"SUPER::$sub"}(@_);
        $ret = return_for_op($ret, $sub);
        return $ret;
    };
    
    my $multi = "$sub\_multi";
    *{$multi} = sub {
        my $self = shift;
        my $ret = $self->${\"SUPER::$multi"}(@_);
        return return_for_multi_wrap(\@_, $ret, $sub)
    };
}

1;

__END__

=head1 NAME

Couchbase::Client::Compat - Cache::Memcached::-compatible interface

=head1 DESCRIPTION

This subclasses and wraps L<Couchbase::Client> to provide backwards-compatibility
with older code using L<Cache::Memcached> or L<Cache::Memcached::Fast>. See either
of those pages for documentation of the methods supported.

=head2 SUPPORTED METHODS

=over

=item get, get_multi

=item gets, gets_multi

=item set, set_multi

=item cas, cas_multi

=item add, add_multi

=item replace, replace_multi

=item append, append_multi

=item prepend, prepend_multi

=item incr, incr_multi

=item decr, decr_multi

=item delete, remove, delete_multi, remove_multi

=back


=head2 SEE ALSO

L<Cache::Memcached>

L<Cache::Memcached::Fast>

L<Cache::Memcached::libmemcached>


=head1 AUTHOR & COPYRIGHT

Copyright (C) 2012 M. Nunberg

You may use and distribute this software under the same terms, licensing, and
conditions as perl itself.
