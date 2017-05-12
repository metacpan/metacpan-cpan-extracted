package App::Genpass;
# ABSTRACT: Quickly and easily create secure passwords
$App::Genpass::VERSION = '2.401';
use Carp;
use Moo;
use Sub::Quote 'quote_sub';
use MooX::Types::MooseLike::Base qw/Int Str Bool ArrayRef/;
use Getopt::Long qw/:config no_ignore_case/;
use File::Spec;
use Config::Any;
use File::HomeDir;
use List::AllUtils qw( any none shuffle );
use Math::Random::Secure;

sub _rand ($) { Math::Random::Secure::rand(shift) }

has uppercase => (
    is      => 'ro',
    isa     => ArrayRef,
    default => quote_sub( q{ [ 'A' .. 'Z' ] } ),
);

has lowercase => (
    is      => 'ro',
    isa     => ArrayRef,
    default => quote_sub( q{ [ 'a' .. 'z' ] } ),
);

has numerical => (
    is      => 'ro',
    isa     => ArrayRef,
    default => quote_sub( q{ [ '0' .. '9' ] } ),
);

has unreadable => (
    is      => 'ro',
    isa     => ArrayRef,
    default => quote_sub( q{ [ split //sm, q{oO0l1I} ] } ),
);

has specials => (
    is      => 'ro',
    isa     => ArrayRef,
    default => quote_sub( q{ [ split //sm, q{!@#$%^&*()} ] } ),
);

has number => (
    is      => 'ro',
    isa     => Int,
    default => quote_sub( q{1} ),
);

has readable => (
    is      => 'ro',
    isa     => Bool,
    default => quote_sub( q{1} ),
);

has verify => (
    is      => 'ro',
    isa     => Bool,
    default => quote_sub( q{1} ),
);

has length => (
    is  => 'ro',
    isa => Int,
);

has minlength => (
    is      => 'rw',
    isa     => Int,
    default => quote_sub( q{8} ),
);

has maxlength => (
    is      => 'rw',
    isa     => Int,
    default => quote_sub( q{10} ),
);

sub parse_opts {
    my $class = shift;
    my %opts  = ();

    GetOptions(
        'configfile=s'  => \$opts{'configfile'},
        'lowercase=s@'  => \$opts{'lowercase'},
        'uppercase=s@'  => \$opts{'uppercase'},
        'numerical=i@'  => \$opts{'numerical'},
        'unreadable=s@' => \$opts{'unreadable'},
        'specials=s@'   => \$opts{'specials'},
        'n|number=i'    => \$opts{'number'},
        'r|readable!'   => \$opts{'readable'},
        'v|verify!'     => \$opts{'verify'},
        'l|length=i'    => \$opts{'length'},
        'm|minlength=i' => \$opts{'minlength'},
        'x|maxlength=i' => \$opts{'maxlength'},
    ) or croak q{Can't get options.};

    # remove undefined keys
    foreach my $key ( keys %opts ) {
        defined $opts{$key} or delete $opts{$key};
    }

    return %opts;
}

sub new_with_options {
    my $class   = shift;
    my %opts    = $class->parse_opts;
    my @configs = (
        File::Spec->catfile( File::HomeDir->my_home, '.genpass.yaml' ),
        '/etc/genpass.yaml',
    );

    if ( ! exists $opts{'configfile'} ) {
        foreach my $file (@configs) {
            if ( -e $file && -r $file ) {
                $opts{'configfile'} = $file;
                last;
            }
        }
    }

    if ( exists $opts{'configfile'} ) {
        %opts = (
            %opts,
            %{ $class->get_config_from_file( $opts{'configfile'} ) },
        );
    }

    my $self = $class->new( %opts, @_ );

    return $self;
}

sub get_config_from_file {
    my ($class, $file) = @_;

    $file = $file->() if ref $file eq 'CODE';
    my $files_ref = ref $file eq 'ARRAY' ? $file : [$file];

    my $can_config_any_args = $class->can('config_any_args');
    my $extra_args = $can_config_any_args ?
        $can_config_any_args->($class, $file) : {};
    ;
    my $raw_cfany = Config::Any->load_files({
        %$extra_args,
        use_ext         => 1,
        files           => $files_ref,
        flatten_to_hash => 1,
    } );

    my %raw_config;
    foreach my $file_tested ( reverse @{$files_ref} ) {
        if ( ! exists $raw_cfany->{$file_tested} ) {
            warn qq{Specified configfile '$file_tested' does not exist, } .
                qq{is empty, or is not readable\n};
                next;
        }

        my $cfany_hash = $raw_cfany->{$file_tested};
        die "configfile must represent a hash structure in file: $file_tested"
            unless $cfany_hash && ref $cfany_hash && ref $cfany_hash eq 'HASH';

        %raw_config = ( %raw_config, %{$cfany_hash} );
    }

    \%raw_config;
}

sub _get_chars {
    my $self      = shift;
    my @all_types = qw( lowercase uppercase numerical specials );
    my @chars     = ();
    my @types     = ();

    # adding all the combinations
    foreach my $type (@all_types) {
        if ( my $ref = $self->$type ) {
            push @chars, @{$ref};
            push @types, $type;
        }
    }

    # removing the unreadable chars
    if ( $self->readable ) {
        my @remove_chars = (
            @{ $self->unreadable },
            @{ $self->specials   },
        );

        @chars = grep {
            local $a = $_;
            none { $a eq $_ } @remove_chars;
        } @chars;

        # removing specials
        pop @types;
    }

    # make both refs
    return [ \@types, @chars ];
}

sub generate {
    my ( $self, $number ) = @_;

    my $length;
    my $verify        = $self->verify;
    my @passwords     = ();
    my @verifications = ();
    my $EMPTY         = q{};

    my ( $char_types, @chars ) = @{ $self->_get_chars };

    my @char_types   = @{$char_types};
    my $num_of_types = scalar @char_types;

    if ( (defined($self->length) && $num_of_types > $self->length)
         || ($num_of_types > $self->minlength) ) {
        $length = defined($self->length) ? $self->length : $self->minlength.' minimum';
        croak <<"_DIE_MSG";
You wanted a shorter password that the variety of characters you've selected.
You requested $num_of_types types of characters but only have $length length.
_DIE_MSG
    }

    if ($self->minlength > $self->maxlength) {
        carp "minlength > maxlength, so I'm switching them";
        my $min = $self->maxlength;
        $self->maxlength($self->minlength);
        $self->minlength($min);
    }

    $length = $self->length
            || $self->minlength + int(_rand(abs($self->maxlength - $self->minlength) + 1));

    $number ||= $self->number;

    # each password iteration needed
    foreach my $pass_iter ( 1 .. $number ) {
        my $password  = $EMPTY;
        my $char_type = shift @char_types;

        # generating the password
        while ( $length > length $password ) {
            my $char = $chars[ int _rand @chars ];

            # for verifying, we just check that it has small capital letters
            # if that doesn't work, we keep asking it to get a new random one
            # the check if it has large capital letters and so on
            if ( $verify && $char_type && @{ $self->$char_type } ) {
                # verify $char_type
                if ( @{ $self->$char_type } ) {
                    while ( ! any { $_ eq $char } @{ $self->$char_type } ) {
                        $char = $chars[ int _rand @chars ];
                    }
                }

                $char_type =
                    scalar @char_types > 0 ? shift @char_types : $EMPTY;
            }

            $password .= $char;
        }

        # since the verification process creates a situation of ordered types
        # (lowercase, uppercase, numerical, special)
        # we need to shuffle the string
        $password = join $EMPTY, shuffle( split //sm, $password );

        $number == 1 && return $password;

        push @passwords, $password;

        @char_types = @{$char_types};
    }

    return wantarray ? @passwords : \@passwords;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Genpass - Quickly and easily create secure passwords

=head1 VERSION

version 2.401

=head1 SYNOPSIS

    use App::Genpass;

    my $genpass = App::Genpass->new();
    print $genpass->generate, "\n";

    $genpass = App::Genpass->new( readable => 0, length => 20 );
    print "$_\n" for $genpass->generate(10);

=head1 DESCRIPTION

If you've ever needed to create 10 (or even 10,000) passwords on the fly with
varying preferences (lowercase, uppercase, no confusing characters, special
characters, minimum length, etc.), you know it can become a pretty pesky task.

This module makes it possible to create flexible and secure passwords, quickly
and easily.

    use App::Genpass;
    my $genpass = App::Genpass->new();

    my $single_password    = $genpass->generate(1);  # returns scalar
    my @single_password    = $genpass->generate(1);  # returns array
    my @multiple_passwords = $genpass->generate(10); # returns array again
    my $multiple_passwords = $genpass->generate(10); # returns arrayref

This distribution includes a program called B<genpass>, which is a command line
interface to this module. If you need a program that generates passwords, use
B<genpass>.

=for stopwords boolean DWIM DWYM arrayref perldoc Github CPAN's AnnoCPAN CPAN

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new instance. It gets a lot of options.

=head2 new_with_options

Creates a new instance while reading the command line parameters.

=head2 parse_opts

Parses the command line options.

=head2 configfile

An attribute defining the configuration file that will be used. If one is not
provided, it tries to find one on its own. It checks for a C<.genpass.yaml> in
your home directory (using L<File::HomeDir>), and then for C</etc/genpass.yaml>.

If one is available, that's what it uses. Otherwise nothing.

You must use the C<new_with_options> method described above for this.

=head3 flags

These are boolean flags which change the way App::Genpass works.

=over 4

=item number

You can decide how many passwords to create. The default is 1.

This can be overridden per I<generate> so you can have a default of 30 but in a
specific case only generate 2, if that's what you want.

=item readable

Use only readable characters, excluding confusing characters: "o", "O", "0",
"l", "1", "I", and special characters such as '#', '!', '%' and other symbols.

You can overwrite what characters are considered unreadable under "character
attributes" below.

Default: on.

=item verify

Verify that every type of character wanted (lowercase, uppercase, numerical,
specials, etc.) are present in the password. This makes it just a tad slower,
but it guarantees the result. Best keep it on.

To emphasize how "slower" it is: if you create 500 passwords of 500 character
length, using C<verify> off, will make it faster by 0.1 seconds.

Default: on.

=back

=head3 attributes

=over 4

=item minlength

The minimum length of password to generate.

Default: 8.

=item maxlength

The maximum length of password to generate.

Default: 10.

=item length

Use this if you want to explicitly specify the length of password to generate.

=back

=head3 character attributes

These are the attributes that control the types of characters. One can change
which lowercase characters will be used or whether they will be used at all,
for example.

    # only a,b,c,d,e,g will be consdered lowercase and no uppercase at all
    my $gp = App::Genpass->new( lowercase => [ 'a' .. 'g' ], uppercase => [] );

=over 4

=item lowercase

All lowercase characters, excluding those that are considered unreadable if the
readable flag (described above) is turned on.

Default: [ 'a' .. 'z' ] (not including excluded chars).

=item uppercase

All uppercase characters, excluding those that are considered unreadable if the
readable flag (described above) is turned on.

Default: [ 'A' .. 'Z' ] (not including excluded chars).

=item numerical

All numerical characters, excluding those that are considered unreadable if the
readable flag (described above) is turned on.

Default: [ '0' .. '9' ] (not including excluded chars).

=item unreadable

All characters which are considered (by me) unreadable. You can change this to
what you consider unreadable characters. For example:

    my $gp = App::Genpass->new( unreadable => [ qw(jlvV) ] );

After all the characters are set, unreadable characters will be removed from all
sets.

Thus, unreadable characters override all other sets. You can make unreadable
characters not count by using the C<< readable => 0 >> option, described by
the I<readable> flag above.

=item specials

All special characters.

Default: [ '!', '@', '#', '$', '%', '^', '&', '*', '(', ')' ].

(not including excluded chars)

=back

=head2 generate

This method generates the password or passwords.

It accepts an optional parameter indicating how many passwords to generate.

    $gp = App::Genpass->new();
    my @passwords = $gp->generate(300); # 300 passwords to go

If you do not provide a parameter, it will use the default number of passwords
to generate, defined by the attribute B<number> explained above.

This method tries to be tricky and DWIM (or rather, DWYM). That is, if you
request it to generate only one password and use scalar context
(C<< my $p = $gp->generate(1) >>), it will return a single password.

However, if you try to generate multiple passwords and use scalar context
(C<< my $p = $gp->generate(30) >>), it will return an array reference for the
passwords.

Generating passwords with list context (C<< my @p = $gp->generate(...) >>)
will always return a list of the passwords, even if it's a single password.

=head2 get_config_from_file

Reads the configuration file using L<Config::Any>.

Shamelessly lifted from L<MooseX::SimpleConfig>.

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 DEPENDENCIES

L<Carp>

L<Moo>

L<MooX::Types::MooseLike>

L<Getopt::Long>

L<File::Spec>

L<Config::Any>

L<File::HomeDir>

L<List::AllUtils>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-app-genpass at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Genpass>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Genpass

You can also look for information at:

=over 4

=item * Github: App::Genpass repository

L<http://github.com/xsawyerx/app-genpass>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Genpass>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Genpass>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Genpass>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Genpass/>

=back

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
