package CTK::ConfGenUtil;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::ConfGenUtil - Config::General structure utility functions

=head1 VERSION

Version 2.69

=head1 SYNOPSIS

    use CTK::ConfGenUtil;

    # <Foo>
    #   <Bar>
    #     Baz qux
    #   </Bar>
    # </Foo>
    my $foo = node( $config, 'foo' ); # { bar => { baz => 'qux' } }
    my $bar = node( $config, 'foo', 'bar' ); # { baz => 'qux' }
    my $bar = node( $config, ['foo', 'bar'] ); # { baz => 'qux' }
    my $bar = node( $config, 'foo/bar' ); # { baz => 'qux' }
    my $baz = value( $config, 'foo/bar/baz' ); # qux

    # Foo bar
    my $foo = value( $config, 'foo' ); # bar

    # Foo 123
    # Foo 456
    # Foo 789
    my $foo = array( $config, 'foo' ); # [123,456,789]

    # <Foo>
    #   Bar baz
    # </Foo>
    my $foo = hash( $config, 'foo' ); # { bar => 'baz' }

    # <Foo>
    #   <Bar>
    #     Baz blah-blah-blah
    #     Qux 123
    #     Qux 456
    #     Qux 789
    #   </Bar>
    # </Foo>
    is_scalar( $foo );
    print "Is scalar : ", is_scalar($config, 'foo/bar/baz') ? 'OK' : 'NO'; # OK

    is_array( $foo );
    print "Is array  : ", is_array($config, 'foo/bar/qux') ? 'OK' : 'NO'; # OK

    is_hash( $foo );
    print "Is hash   : ", is_hash($config, 'foo/bar') ? 'OK' : 'NO';  # OK

=head1 DESCRIPTION

This module based on L<Config::General::Extended>

=head2 FUNCTIONS

Working sample:

    <Foo>
      <Bar>
        Baz blah-blah-blah
        Qux 123
        Qux 456
        Qux 789
      </Bar>
    </Foo>

=over 8

=item B<node>

This method returns the found node of a given key.

    my $bar = node( $config, 'foo', 'bar' );
    my $bar = node( $config, ['foo', 'bar'] );
    my $bar = node( $config, 'foo/bar' );
    my $bar = node( $config, ['foo/bar'] );

    my $bar_hash = hash($bar);
    my $baz = value($bar, 'baz'); # blah-blah-blah

=item B<value>

This method returns the scalar value (first) of a given key.

    my $baz = value( $config, 'foo/bar/baz' );

=item B<lvalue>

This method returns the scalar value (last) of a given key.

    my $baz = lvalue( $config, 'foo/bar/baz' );

=item B<array>

This method returns a array reference (if it B<is> one!) from the config which is referenced by
"key". Given the sample config above you would get:

    my $qux = array( $config, 'foo/bar/qux' );

=item B<hash>

This method returns a hash reference (if it B<is> one!) from the config which is referenced by
"key". Given the sample config above you would get:

    my $bar = hash( $config, 'foo/bar' );

=item B<is_scalar>, B<is_value>

As seen above, you can access parts of your current config using hash, array or scalar
functions. This function returns just true if the given key is scalar (regular value)

    is_scalar( $baz );
    is_scalar( $config, 'foo/bar/baz' );

=item B<is_array>

As seen above, you can access parts of your current config using hash, array or scalar
functions. This function returns just true if the given key is array (reference)

    is_array( $qux );
    is_array( $config, 'foo/bar/qux' );

=item B<is_hash>

As seen above, you can access parts of your current config using hash, array or scalar
functions. This function returns just true if the given key is hash (reference)

    is_hash( $bar );
    is_hash( $config, 'foo/bar' );

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<Config::General::Extended>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '2.69';

use base qw/Exporter/;

# Default export (all):
our @EXPORT = qw/ node value lvalue array hash is_value is_scalar is_array is_hash /;
# Required only:
our @EXPORT_OK = qw/ node value lvalue array hash is_value is_scalar is_array is_hash /;

sub node {
    #
    #  getnode( $config, [qw/foo bar baz/] )
    #  getnode( $config, qw/foo bar baz/ )
    #  getnode( $config, 'foo' )
    #  getnode( $config, 'foo', 'bar/baz' )
    #
    my $cc = shift || {};
    my $ar = shift || [];
    my %rcc = ();
    %rcc = %$cc if ref($cc) eq 'HASH';
    my @arcc = ();
    @arcc = @$cc if ref($cc) eq 'ARRAY';
    my @rar = ();
    if (ref($ar) eq 'ARRAY') {
        push @rar, split(/\//, $_) for (grep {$_} (@$ar));
    } else {
        push @rar, split(/\//, $_) for (grep {$_} ($ar,@_));
    }

    my $tnode = \%rcc;
    my $laststat = 0;

    foreach my $k (@rar) {
        #debug $k;
        if ($tnode && (ref($tnode) eq 'HASH') && defined($tnode->{$k})) {
            $tnode = $tnode->{$k};
            $laststat = 1;
        } else {
            #debug Dumper($tnode);
            $laststat = 0;
            next;
        }
    }
    if (!$laststat && @arcc && defined($arcc[0])) {
        my $kk = pop(@rar) || '';
        if ($kk) {
            foreach my $an (@arcc) {
                if ($an && (ref($an) eq 'HASH') && defined($an->{$kk})) {
                    $tnode = $an->{$kk};
                    $laststat = 1;
                    last;
                }
            }
        }
    }

    return $laststat ? $tnode : undef;
}
sub value {
    my $node = shift;
    $node = node($node, @_) if defined($_[0]);
    if ($node && ref($node) eq 'ARRAY') {
        return exists($node->[0]) ? $node->[0] : undef;
    } elsif (defined($node) && !ref($node)) {
        return $node
    } else {
        return undef
    }
}
sub lvalue {
    my $node = shift;
    $node = node($node, @_) if defined($_[0]);
    if ($node && ref($node) eq 'ARRAY') {
        return exists($node->[0]) ? $node->[-1] : undef;
    } elsif (defined($node) && !ref($node)) {
        return $node
    } else {
        return undef
    }
}
sub array {
    my $node = shift;
    $node = node($node, @_) if defined $_[0];
    if ($node && ref($node) eq 'ARRAY') {
        return $node;
    } elsif (defined($node) && !ref($node)) {
        return [$node];
    } else {
        return [];
    }
}
sub hash {
    my $node = shift || {};
    $node = node($node, @_) if defined $_[0];
    if ($node && ref($node) eq 'HASH') {
        return $node;
    } else {
        return {};
    }
}
sub is_hash {
    my $node = shift;
    $node = node($node, @_) if defined($_[0]);
    return 1 if $node && ref($node) eq 'HASH';
    return;
}
sub is_array {
    my $node = shift;
    $node = node($node,@_) if defined($_[0]);
    return 1 if $node && ref($node) eq 'ARRAY';
    return;
}
sub is_value {
    my $node = shift;
    $node = node($node, @_) if defined($_[0]);
    return 1 if defined($node) && !ref($node);
    return;
}
sub is_scalar { goto &is_value }

1;

__END__
