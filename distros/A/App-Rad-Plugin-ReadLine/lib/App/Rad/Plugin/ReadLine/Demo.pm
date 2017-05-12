package App::Rad::Plugin::ReadLine::Demo;
BEGIN {
  $App::Rad::Plugin::ReadLine::Demo::VERSION = '0.002';
}
# ABSTRACT: export &demo into your App::Rad app, so you can use ExampleRunner in the pod


our @EXPORT_OK = ('&demo', '&getopt');
use base Exporter;


sub demo  #   : Help('run shell commands from @ARGV')
{
    my $c=shift;
    no warnings qw[ redefine ];
    my @answers = (@ARGV, qw[ exit ]);
    *Term::UI::get_reply = sub { 
        my $self= shift;
        my %args = @_;
        my $answer = shift @answers;
        print $args{prompt},$answer, "\n";
        $answer;
    };
    if (@answers) { 
        local $c->{'cmd'} = shift @answers;
        $c->execute();
    }
    else { 
        $c->shell();
    }
    ''
}

sub getopt 
    #:Help('see what getopt makes of commands')
{
    my $c = shift;
    use Data::Dumper;
    Data::Dumper->Dump(
        [ $c->options, $c->argv, \@ARGV ],
        [qw( $c->options $c->argv @ARGV)]
    );
}



__END__
=pod

=head1 NAME

App::Rad::Plugin::ReadLine::Demo - export &demo into your App::Rad app, so you can use ExampleRunner in the pod

=head1 VERSION

version 0.002

=head1 what?!

this is a little bit of trickery that adds an action to your App::Rad app 
that lets me run App::Rad::RreadLine commands by listing their names 
as arguments to the application.

=head1 EXPORTS

I love export based interfaces. 

both are available on request ...

=head2 C<&demo>

which then calls the actions listed
replaces C<Term::UI>'s C<get_reply> method so that C<App::Rad::Plugin::ReadLine> thinks that users are typing those commands ...

and then calls the first action listed in @ARGV to get the ball rolling.

=head2 C<&getopt>

an action that dumps C<< $c->options, $c->argv, @ARGV >>, to convince you
(and me) that App::Rad is being passed arguments that make sense based on what
is typed in by the user...

This would be beter done in the test suite...

=head1 BUGS

Please report any bugs or feature requests to bug-app-rad-plugin-readline@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=App-Rad-Plugin-ReadLine

=head1 AUTHOR

FOOLISH <FOOLISH@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by FOOLISH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

