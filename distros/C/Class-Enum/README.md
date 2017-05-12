# NAME

Class::Enum - typed enum

# SYNOPSIS

## Simple usage.

Define \`Direction\`,

    # Direction.pm
    package Direction;
    use Class::Enum qw(Left Right);

and using.

    # using
    use Direction qw(Left Right);
    

    # default properties
    print Left ->name; # 'Left'
    print Right->name; # 'Right
    print Left ->ordinal; # 0
    print Right->ordinal; # 1
    

    print Left ->is_left;  # 1
    print Left ->is_right; # ''
    print Right->is_left;  # ''
    print Right->is_right; # 1
    

    # compare by ordinal
    print Left() <=> Right; # -1
    print Left() <   Right; # 1
    print Left() <=  Right; # 1
    print Left() >   Right; # ''
    print Left() >=  Right; # ''
    print Left() ==  Right; # ''
    print Left() !=  Right; # 1
    

    # compare by name
    print Left() cmp Right; # -1
    print Left() lt  Right; # 1
    print Left() le  Right; # 1
    print Left() gt  Right; # ''
    print Left() ge  Right; # ''
    print Left() eq  Right; # ''
    print Left() ne  Right; # 1
    

    # list values
    print join("\n",                                                 # '0: Left
               map { sprintf('%d: %s', $_, $_) } Direction->values); #  1: Right'
    

    # list names
    print join(', ', Direction->names); # 'Left, Right'
    

    # retrieve value of name
    print Left() == Direction->value_of('Left'); # 1

    # retrieve value of ordinal
    print Left() == Direction->from_ordinal(0); # 1
    

    # type
    print ref Left; # 'Direction'

## Advanced usage.

Define \`Direction\`,

    # Direction.pm
    package Direction;
    use Class::Enum (
        Left  => { delta => -1 },
        Right => { delta =>  1 },
    );
    

    sub move {
        my ($self, $pos) = @_;
        return $pos + $self->delta;
    }

and using.

    # using
    use Direction qw(Left Right);
    

    my $pos = 5;
    print Left->move($pos);  # 4
    print Right->move($pos); # 6

## Override default properties. (Unrecommended)

Define \`Direction\`,

    # Direction.pm
    package Direction;
    use Class::Enum (
        Left   => { name => 'L', ordinal => -1 },
        Center => { name => 'C' }
        Right  => { name => 'R' },
    );

and using.

    # using
    use Direction qw(Left Center Right);
    

    my $pos = 5;
    print $pos + Left;   # 4
    print $pos + Center; # 5
    print $pos + Right;  # 6
    

    print 'Left is '   . Left;   # 'Left is L'
    print 'Center is ' . Center; # 'Center is C'
    print 'Right is '  . Right;  # 'Right is R'

## Override overload

Define \`Direction\`,

    # Direction.pm
    package Direction;
    use Class::Enum qw(Left Right), -overload => { '""' => sub { $_[0]->ordinal } };

and using.

    # using
    use Direction qw(Left Right);
    print 'Left is '  . Left;  # 'Left is 0'
    print 'Right is ' . Right; # 'Right is 1'

## Use alternate exporter.

Define \`Direction\`,

    # Direction.pm
    package Direction;
    use Class::Enum qw(Left Right), -install_exporter => 0; # No install 'Exporter'
    use parent 'Exporter::Tiny';
    our @EXPORT_OK = __PACKAGE__->names();

and using.

    # using
    use Direction Left  => { -as => 'L' },
                  Right => { -as => 'R' };

    print L->name; # 'Left'
    print R->name; # 'Right

# DESCRIPTION

Class::Enum provides behaviors of typed enum, such as a Typesafe enum in java.

# LICENSE

Copyright (C) keita.iseki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

keita.iseki <keita.iseki+cpan at gmail.com>
