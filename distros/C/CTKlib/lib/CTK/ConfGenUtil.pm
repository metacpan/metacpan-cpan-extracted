package CTK::ConfGenUtil; # $Id: ConfGenUtil.pm 192 2017-04-28 20:40:38Z minus $
use strict;

=head1 NAME

CTK::ConfGenUtil - Config::General structure utility functions

=head1 VERSION

Version 2.66

=head1 SYNOPSIS

    use CTK;
    use CTK::ConfGenUtil;
    my $c = new CTK;
    my $config = $c->config;

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
    say "Is scalar : ", is_scalar($config, 'foo/bar/baz') ? 'OK' : 'NO'; # OK

    is_array( $foo );
    say "Is array  : ", is_array($config, 'foo/bar/qux') ? 'OK' : 'NO'; # OK

    is_hash( $foo );
    say "Is hash   : ", is_hash($config, 'foo/bar') ? 'OK' : 'NO';  # OK

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

This method returns the scalar value of a given key.

    my $baz = value( $config, 'foo/bar/baz' );

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

=item B<exists>

Reserved. Coming soon

This method returns just true if the given key exists in the config.

=back

=head1 SEE ALSO

L<Config::General::Extended>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use vars qw/$VERSION/;
$VERSION = '2.66';

use base qw/Exporter/;
our @EXPORT = qw/ node value array hash is_value is_scalar is_array is_hash exists /;

sub node {
    # Получение подструктуры относительно структуры заданной в первом аргументе.
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

    # Пробегаемся вглубь
    my $tnode = \%rcc;
    my $laststat = 0;

    # Ищем стандартным способом
    foreach my $k (@rar) {
        #debug $k;
        if ($tnode && (ref($tnode) eq 'HASH') && defined $tnode->{$k}) {
            $tnode = $tnode->{$k};
            $laststat = 1;
        } else {
            #debug "Мимо ($k) :(";
            #debug Dumper($tnode);
            $laststat = 0;
            next;
        }
    }

    # Ищем НЕстандартным способом
    if (!$laststat && @arcc && defined $arcc[0]) {
        my $kk = pop(@rar) || '';
        if ($kk) {
            #debug "Попали на массив :)";
            foreach my $an (@arcc) {
                if ($an && (ref($an) eq 'HASH') && defined $an->{$kk}) {
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
    # Получение скалярного значения или undef
    my $node = shift;
    $node = node($node,@_) if defined $_[0];
    if ($node && ref($node) eq 'ARRAY') {
        return exists $node->[0] ? $node->[0] : undef;
    } elsif (defined($node) && !ref($node)) {
        return $node
    } else {
        return undef
    }
}
sub array {
    # Получение смассива значениий или пустой массив (ссылка на него)
    my $node = shift;
    $node = node($node,@_) if defined $_[0];
    if ($node && ref($node) eq 'ARRAY') {
        return $node;
    } elsif (defined($node) && !ref($node)) {
        return [$node];
    } else {
        return [];
    }
}
sub hash {
    # Получение хэша значениий или пустой хэш (ссылка на него)
    my $node = shift || {};
    $node = node($node,@_) if defined $_[0];
    if ($node && ref($node) eq 'HASH') {
        return $node;
    } else {
        return {};
    }
}
sub is_hash {
    # Возвращает истину если значение является хэшем (ссылкой на него)
    my $node = shift;
    $node = node($node,@_) if defined $_[0];
    return 1 if $node && ref($node) eq 'HASH';
    return;
}
sub is_array {
    # Возвращает истину если значение является массивом (ссылкой на него)
    my $node = shift;
    $node = node($node,@_) if defined $_[0];
    return 1 if $node && ref($node) eq 'ARRAY';
    return;
}
sub is_value {
    # Возвращает истину если значение является скаляром
    my $node = shift;
    $node = node($node,@_) if defined $_[0];
    return 1 if defined $node && !ref($node);
    return;
}
sub is_scalar { goto &is_value }
sub exists { 1 } # Coming soon

1;
__END__
