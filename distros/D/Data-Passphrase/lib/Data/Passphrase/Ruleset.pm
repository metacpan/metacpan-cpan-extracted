# $Id: Ruleset.pm,v 1.6 2007/08/14 15:45:51 ajk Exp $

use strict;
use warnings;

package Data::Passphrase::Ruleset; {
    use Object::InsideOut;

    use Data::Passphrase::Rule;
    use Carp;

    # object attributes
    my @debug         :Field( Std => 'debug',         Type => 'Numeric'  );
    my @file          :Field( Get => 'get_file',                         );
    my @passing_score :Field( Std => 'passing_score', Type => 'Numeric'  );
    my @rules         :Field( Get => 'get_rules',                        );

    my %init_args :InitArgs = (
        debug => {
            Def   => 0,
            Field => \@debug,
            Type  => 'Numeric',
        },
        file => {
            Field => \@file,
            Pre   => \&preprocess,
        },
        passing_score => {
            Def   => 0.6,
            Field => \@passing_score,
            Type  => 'Numeric',
        },
        rules => {
            Field => \@rules,
            Pre   => \&preprocess,
            Type  => 'Array_ref',
        },
    );

    sub preprocess {
        my ($class, $name, $init_ref, $self, $value) = @_;

        # file & rules attributes are mutually exclusive
        if (defined $value) {
            croak 'file & rules cannot be supplied simultaneously'
                if $name eq 'file'  && defined $self->get_rules()
                || $name eq 'rules' && defined $self->get_file ();
        }

        return $value;
    }
    # overload constructor so we can automatically load the rules file
    sub new {
        my ($class, $arg_ref) = @_;

        # unpack arguments
        my $debug = $arg_ref->{debug};

        $debug and warn 'initializing ', __PACKAGE__, ' object';

        # construct object
        my $self = $class->Object::InsideOut::new($arg_ref);

        # load rules from file
        if (exists $arg_ref->{file}) {
            $self->load();
        }

        return $self;
    }

    # cache rulesets by filename
    my %Rules_Cache;

    # load the rules file if we need to
    sub load {
        my ($self) = @_;

        # unpack arguments
        my $debug = $self->get_debug();
        my $file  = $self->get_file () or croak 'file attribute undefined';

        $debug and warn "$file: checking readability";
        my $last_modified = 0;
        if (-r $file) {

            # point the object attribute at the current ruleset
            $Rules_Cache{$file}{rules} ||= [];
            $self->set(\@rules, $Rules_Cache{$file}{rules});

            # don't re-read if file hasn't been modified since last time
            $last_modified = (stat _)[9];
            $debug and warn "$file: pid: $$, mod time: $last_modified, ",
                "last processed: ", $Rules_Cache{$file}{last_read};
            return if exists $Rules_Cache{$file}{last_read}
                          && $Rules_Cache{$file}{last_read} == $last_modified;

            # read the configuration file
            $debug and warn "$file: processing";
            my $rule_list = do $file;
            if (ref $rule_list ne 'ARRAY') {
                croak "$file: parse error: $@" if $@;
                croak "$file: $!"              if $!;
                croak "$file: must return a reference to an array of rules";
            }

            push @{ $Rules_Cache{$file}{rules} }, map {
                ref eq 'HASH'
                    ? Data::Passphrase::Rule->new(
                        { %$_, debug => $debug }
                      )
                    : $_
                    ;
            } @$rule_list;
        }

        # limp along if the file went away, unless this is the first run
        else {
            warn "$file: $!";
            die if !exists $Rules_Cache{$file}{last_read};
        }

        # cache the timestamp for comparison in later calls
        $Rules_Cache{$file}{last_read} = $last_modified;
    }

    # load the file after setting the file attribute
    sub set_file {
        my ($self, $value) = @_;
        my $return_value = $self->set(\@file, $value);
        if (defined $value) {
            $self->load();
        }
        return $return_value;
    }

    # clear file attribute if rules are loaded directly
    sub set_rules {
        my ($self, $value) = @_;

        # check type
        croak 'rules attribute may only be set to an array reference'
            if ref $value ne 'ARRAY';

        my $return_value = $self->set(\@rules, $value);
        $self->set_file();

        return $return_value;
    }
}

1;
__END__

=head1 NAME

Data::Passphrase::Ruleset - ruleset for validating passphrases

=head1 SYNOPSIS

Specified by script file:

    my $ruleset = Data::Passphrase::Ruleset->new({
        debug => 1,
        file  => '/usr/local/etc/passphrase/rules',
    });
    
    my $passphrase_object = Data::Passphrase->new({
        ruleset => $ruleset,       # putting the filename here also works
    });

Passing rules in as L<Data::Passphrase::Rule|Data::Passphrase::Rule>
objects or directly:

    my $rule = Data::Passphrase::Rule->new({
       code     => 450,
       message  => 'is too short',
       test     => 'X' x 15,
       validate => sub { $_[0] >= 15 },
    });
    
    my $ruleset = Data::Passphrase::Ruleset->new({
        rules  => [
           $rule,
           {
               code     => 452,
               message  => 'may not contain # or @',
               test     => [
                   'this passphrase contains #',
                   '@ appears in this one',
               ],
               validate => sub { $_[0] !~ /([#@])/ },
           },
        ]
    });
    
    my $passphrase_object = Data::Passphrase->new({
        ruleset => $ruleset,
    });

=head1 DESCRIPTION

Objects of this class represent a list of strength-checking rules used
by L<Data::Passphrase|Data::Passphrase>.  In addition to constructor
and accessor methods, it provides a method to load rules from a Perl
script.

=head1 INTERFACE

There is a constructor, C<new>, which takes a reference to a hash of
initial attribute settings, and accessor methods of the form
get_I<attribute>() and set_I<attribute>().  See L</Attributes>.

=head2 Methods

In addition to the constructor and accessor methods, the following
special method is available.

=head3 load()

    $self->load()

Load or reload rules from the Perl script specified by the
L<file|/file> attribute.  Rules are only reloaded if the script has
been modified since the last time it was evaluated.  Either way, after
a L<load()/load()>, the L<rules|/rules> attribute will point to an
up-to-date copy of the rules.

=head2 Attributes

The attributes below can be accessed via methods of the form
get_I<attribute>() and set_I<attribute>().

=head3 debug

If TRUE, enable debugging to the Apache error log.

=head3 file

The filename of a Perl script that, when evaluated, returns a list of
rules.  Each rule is specified as either an
L<Data::Passphrase::Rule|Data::Passphrase::Rule> object or a hash
reference used to construct one.

=head3 passing_score

The lowest score a rule's validate routine can return for the
passphrase to pass that rule.  Defaults to 0.6.

=head3 rules

A reference to an array of rules.  Each rule is specified as either an
L<Data::Passphrase::Rule|Data::Passphrase::Rule> object or a hash
reference used to construct one.

=head1 EXAMPLES

See L<Data::Passphrase> and the included C<passphrase_rules> file.

=head1 AUTHOR

Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

Data::Passphrase(3), Data::Passphrase::Rule(3)
