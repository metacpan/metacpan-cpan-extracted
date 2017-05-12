{   package Catalyst::Plugin::Log::Message;

    use strict;
    use warnings;

    use base 'Catalyst::Base';

    our $VERSION = '0.02';

    __PACKAGE__->mk_accessors(qw/_logger/);

    sub logger {
        my $c   = shift;
        return $c->_logger || $c->_logger(
                            Catalyst::Plugin::Log::Message::Backend->new($c)
                        );
    }
}


{   package Catalyst::Plugin::Log::Message::Backend;

    use strict;
    use warnings;
    use Data::Dumper;

    use Log::Message;

    use base qw/
            Class::Accessor::Fast
            Class::Data::Inheritable
        /;

    our $VERSION = $Catalyst::Plugin::Log::Message::VERSION;

    __PACKAGE__->mk_accessors(qw/log_object _cat_obj/);
    __PACKAGE__->mk_classdata(qw/supported_levels/);

    __PACKAGE__->supported_levels([ qw/debug info warn error fatal/ ]);

    sub _do_nothing         { };

    {   for my $name ( @{ __PACKAGE__->supported_levels } ) {
            no strict 'refs';

            ### empty sub for the handler
            {   no warnings 'redefine';
                *{"Log::Message::Handlers::".$name} =
                    __PACKAGE__->can('_do_nothing');
            }

            *$name = sub {
                my $self    = shift;
                my $check   = "is_$name";

                ### see if we should print this or not ###
                $self->_cat_obj->log->$name( @_ )
                        unless $name eq 'debug' && !$self->_cat_obj->debug;

                $self->log_object->store(
                    message => "@_",
                    tag     => lc $name,
                    level   => $name,
                );

            }

        }
    }

    sub new {
        my $self    = shift->SUPER::new();
        $self->_cat_obj(shift());
        $self->log_object(Log::Message->new(private => 1));
        return $self;
    }


    sub flush {
        my ($self) = @_;
        return reverse $self->log_object->flush;
    }


    sub stack {
        my ($self) = @_;
        return $self->log_object->retrieve( chrono => 1 );
    }

    sub stack_as_string {
        my $self = shift;
        my $trace = shift() ? 1 : 0;

        return join '', map {
            sprintf "[%s] [%5s] %s\n",
                $_->when, $_->tag,
                ($trace ? $_->message . ' ' . $_->longmess : $_->message);
            } $self->stack;
    }

    sub retrieve {
        my $self = shift;
        my @lvls = @_ or return $self->stack;

        my $re   = join '|', @lvls;
        my @list = $self->log_object->retrieve( chrono => 1, tag => qr/$re/i );

        return @list;
    }

    sub retrieve_last {
        my $self = shift;
        my @list = $self->retrieve( @_ );
        return $list[-1];
    }

}

1;

__END__

=head1 NAME

Catalyst::Plugin::Log::Message - Alternative catalyst log module

=head1 SYNOPSIS

    package MyAPP;

    use Catalyst qw/Log::Message/;

    package MyAPP::Controller::Tester;

    sub logthis : Local {
        my ($self, $c) = @_;

        $c->logger->debug('Entering user mode');
        ### Doing something user here

        if ($msg =~ /no such user/i) {
            $c->logger->error('Ok, critical error, abort');
            ### Send most critical last message to screen of user
            $c->stash->{error} = $c->logger->retrieve_last(qw/error/);

            ### Send stack to file or something
            $c->doing_something_savy($c->logger->stack_as_string);
        }

    }


=head1 DESCRIPTION

C<Catalyst::Log::Message> is an alternative module providing extra logging
possibilities for the developer. Extra options include the possibility to
read the stack of errors from the current request in string or array form,
retrieve the last error matching a specific level etc. The stack is flushed
after every request.

We chose to create another method on the Catalyst context object, because
the log method provided to much information for a good trackdown of errors.

=head1 Object Methods

The following methods are available for the developer.

=head2 $c->logger->flush()

Will flush the stack

=head2 $c->logger->stack()

In scalar context it will return the first item and in list context, it will
return all of them.

=head2 $c->logger->stack_as_string()

Return the entire stack of this request in a stringified way

=head2 $c->logger->retrieve([ $STRINGTAG ])

Retrieve an array of C<Log::Message> objects matching the optional tag (tag can
be error handlers like error,debug,fatal etc)

=head2 $c->logger->retrieve_last([ $STRINGTAG ])

Retrieve the last message on the stack matching the optional tag.

=head1 AUTHOR

This module by
Michiel Ootjers E<lt>michiel@cpan.orgE<gt>.

and

Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Plugin::Log::Message> to
C<bug-catalyst-plugin-log-message@rt.cpan.org>

=head1 COPYRIGHT

This module is
copyright (c) 2002 Michiel Ootjers E<lt>michiel@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut

