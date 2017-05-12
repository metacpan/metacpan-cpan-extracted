package App::JobLog::Command::modify;
$App::JobLog::Command::modify::VERSION = '1.042';
# ABSTRACT: modify last logged event

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse qw(App::JobLog::Log);
no if $] >= 5.018, warnings => "experimental::smartmatch";

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $log = App::JobLog::Log->new;
    my ( $e, $i ) = $log->last_event;
    $self->usage_error('empty log') unless $e;
    my $ll = $e->data;
    if ( $opt->clear_tags ) {
        $ll->tags = [];
    }
    elsif ( $opt->untag ) {
        my %tags = map { $_ => 1 } @{ $ll->tags };
        delete $tags{$_} for @{ $opt->untag };
        $ll->tags = [ sort keys %tags ];
    }
    if ( $opt->tag ) {
        my %tags = map { $_ => 1 } @{ $ll->tags };
        $tags{$_} = 1 for @{ $opt->tag };
        $ll->tags = [ sort keys %tags ];
    }
    my $description = join ' ', @$args;
    for ( $opt->desc || '' ) {
        when ('replace_description') {
            $ll->description = [$description];
        }
        when ('add_description') {
            push @{ $ll->description }, $description;
        }
    }
    $log->replace( $i, $ll );
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o [<description>]' }

sub abstract { 'add details to last event' }

sub options {
    return (
        [
            desc => hidden => {
                one_of => [
                    [ "add-description|a" => "add some descriptive text" ],
                    [
                        "replace-description|r" => "replace current description"
                    ],
                ]
            }
        ],
        [ "tag|t=s@",     "add tag; e.g., -t foo -t bar" ],
        [ "untag|u=s@",   "remove tag; e.g., -u foo -u bar" ],
        [ "clear-tags|c", "remove all tags" ],
    );
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    my $has_modification = grep { $_ } @{$opt}{qw(desc tag untag clear_tags)};
    $self->usage_error('no modification specified') unless $has_modification;

    if ( $opt->desc ) {
        $self->usage_error('no description provided') unless @$args;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::modify - modify last logged event

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job last
 Sunday,  6 March, 2011
   7:36 - 7:37 pm  0.01  widget  something to add                                                                                                                  
 
   TOTAL HOURS 0.01
   widget      0.01
 houghton@NorthernSpy:~$ job modify --help
 job <command>
 
 job modify [-acrtu] [long options...] [<description>]
 	-a --add-description       add some descriptive text
 	-r --replace-description   replace current description
 	-t --tag                   add tag; e.g., -t foo -t bar
 	-u --untag                 remove tag; e.g., -u foo -u bar
 	-c --clear-tags            remove all tags
 	--help                     this usage screen
 houghton@NorthernSpy:~$ job m -a "and still more" -c -t foo -t bar
 houghton@NorthernSpy:~$ job l
 Sunday,  6 March, 2011
   7:36 - 7:37 pm  0.01  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 0.01
   bar         0.01
   foo         0.01

=head1 DESCRIPTION

B<App::JobLog::Command::modify> lets you change anything about the most recent task in the log
other than its timestamp. Often this is all you need to do to fix a mistake and it is a little
easier than editing the log itself.

=head1 SEE ALSO

L<App::JobLog::Command::last>, L<App::JobLog::Command::resume>, L<App::JobLog::Command::today>,
L<App::JobLog::Command::edit>, L<App::JobLog::Command::done>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
