package BPM::Engine::Exceptions;
BEGIN {
    $BPM::Engine::Exceptions::VERSION   = '0.01';
    $BPM::Engine::Exceptions::AUTHORITY = 'cpan:SITETECH';
    }
use strict;
use warnings;

BEGIN {
    my %classes = (
        'BPM::Engine::Exception' => {
            description => 'Generic BPM::Engine exception',
            alias       => 'throw'
            },
        'BPM::Engine::Exception::Engine' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Engine exception',
            alias       => 'throw_engine'
            },
        'BPM::Engine::Exception::Runner' => {
            isa         => 'BPM::Engine::Exception',
            description => 'ProcessRunner exception',
            alias       => 'throw_runner'
            },
        'BPM::Engine::Exception::Database' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Datastore exception',
            alias       => 'throw_store'
            },
        'BPM::Engine::Exception::IO' => {
            isa         => 'BPM::Engine::Exception',
            description => 'IO exception',
            alias       => 'throw_io'
            },
        'BPM::Engine::Exception::Parameter' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Invalid parameters was given to method/function',
            alias       => 'throw_param'
            },
        'BPM::Engine::Exception::Condition' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Condition false error',
            alias       => 'throw_condition'
            },
        'BPM::Engine::Exception::Expression' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Exception evaluator error',
            alias       => 'throw_expression'
            },
        'BPM::Engine::Exception::Plugin' => {
            isa         => 'BPM::Engine::Exception',
            fields      => 'plugin',
            description => 'Plugin exception',
            alias       => 'throw_plugin'
            },
        'BPM::Engine::Exception::Model' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Model exception',
            alias       => 'throw_model'
            },
        'BPM::Engine::Exception::Install' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Installation/configuration exception',
            alias       => 'throw_install'
            },
        'BPM::Engine::Exception::NotImplemented' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Abstract method',
            alias       => 'throw_abstract'
            },
            );

    my @exports = map { $classes{$_}->{alias} } keys %classes;

    require Exception::Class;
    require Sub::Exporter;

    Exception::Class->import(%classes);
    Sub::Exporter->import(-setup => { exports => \@exports });
    }

1;
__END__

=pod

=head1 NAME

BPM::Engine::Exceptions - Exception classes used in BPM::Engine

=head1 VERSION

0.01

=head1 SYNOPSIS

Throw an exception when something is wrong

    use BPM::Engine::Exceptions qw/throw_plugin/;

    sub set_length {
        my ($self, $length) = @_;

        # throw an exception
        throw_plugin("Whoops!") unless $length =~ /\d+/;

        # ...
        }    

Now let's try something illegal and catch the exception    
    
    # use the is_Exception() function exported from the types library
    use BPM::Engine::Types qw/Exception/;    
    
    eval {
        $obj->set_length( 'non-numerical value' ); # this throws the error
        #...
    };
    
    # handle any exception, cathing them in various ways
    if(my $err = $@) {
        # encountered an error
        
        if( Exception::Class->caught('BPM::Engine::Exception::Engine') ) {
            #... use the thrown error obj
            warn $err->error;
            print $err->as_html;
            }
        elsif(my $err = BPM::Engine::Exception::Plugin->caught() ) {
            warn $err->trace->as_string;
            }
        # the type tests blessed $@ && $@->isa('BPM::Engine::Exception')
        elsif( is_Exception($err) ) {
            $err->rethrow();
            }
        else {
            # something bad happened!
            die $@;
            }
        }

C<BPM::Engine::Exception> stringifies to something reasonable, so if you don't
need detailed error information, you can simply treat $@ as a string:

    eval { $engine->update($status) };
    if ( $@ ) {
        warn "update failed because: $@\n";
    }

=head1 DESCRIPTION

This module creates the hierarchy of exception objects used by other BPM::Engine
modules and provides shortcuts to make raising an exception easier and more
readable.

The exceptions are subclasses of Exception::Class::Base, created by the
interface defined by C<Exception::Class>. See 
L<Exception::Class|Exception::Class> for more information on how this is done.

=head1 EXCEPTIONS

Each of the exception classes created by BPM::Engine::Exceptions has a 
functional alias for its throw class method. In the L<SYNOPSIS|/SYNOPSIS> 
example, we use the C<throw_plugin> function to throw a 
C<BPM::Engine::Exception::Plugin> exception.

These may be imported by passing a list of the function names to import:

  use BPM::Engine::Exceptions qw(throw_component);

Some of the exceptions mentioned above have additional fields, which are
available via accessors.

The exception classes created by BPM::Engine::Exceptions are as follows:

=over 4

=item * BPM::Engine::Exception

This is the base class for all generated exceptions.

=item * BPM::Engine::Exception::Engine

Engine exception. Aliased as C<throw_engine>.

=item * BPM::Engine::Exception::Runner

ProcessRunner exception. Aliased as C<throw_runner>.

=item * BPM::Engine::Exception::Database

Datastore exception. Aliased as C<throw_store>.

=item * BPM::Engine::Exception::IO

IO exception. Aliased as C<throw_io>.

=item * BPM::Engine::Exception::Parameter

Invalid parameters was given to method/function. Aliased as C<throw_param>.

=item * BPM::Engine::Exception::Condition

Condition false error. Aliased as C<throw_condition>.

=item * BPM::Engine::Exception::Expression

Exception evaluator error. Aliased as C<throw_expression>.

=item * BPM::Engine::Exception::Plugin

Plugin exception. Extra field: C<plugin>. Aliased as C<throw_plugin>.

=item * BPM::Engine::Exception::Model

Model exception. Aliased as C<throw_model>.

=item * BPM::Engine::Exception::Install

Installation/configuration exception. Aliased as C<throw_install>.

=item * BPM::Engine::Exception::NotImplemented

Abstract method. Aliased as C<throw_abstract>.

=back

=head1 DEPENDENCIES

=over 4

=item * L<Exception::Class|Exception::Class>

=back

=head1 AUTHOR

Peter de Vos <sitetech@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
