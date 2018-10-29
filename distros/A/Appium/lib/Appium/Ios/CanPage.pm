package Appium::Ios::CanPage;
$Appium::Ios::CanPage::VERSION = '0.0804';
# ABSTRACT: Display all interesting elements for iOS, useful during test authoring
use Moo::Role;
use feature qw/state/;


sub page {
    my ($self) = @_;

    return $self->_get_page;
}

sub _get_page {
    my ($self, $element, $level) = @_;

    $element //= $self->_source_window_with_children;
    $level //= 0;
    my $indent = '  ' x $level;

    # App strings are found in an actual file in the app package
    # somewhere, so I'm assuming we don't have to worry about them
    # changing in the middle of our app execution. This may very well
    # turn out to be a false assumption.
    state $strings = $self->app_strings;

    my @details = qw/name label value hint/;
    if ($element->{visible}) {
        print $indent .  $element->{type} . "\n";
        foreach (@details) {
            my $detail = $element->{$_};
            if ($detail) {
                print $indent .  '  ' . $_ . "\t: " . $detail  . "\n" ;

                foreach my $key (keys %{ $strings }) {
                    my $val = $strings->{$key};
                    if ($val =~ /$detail/) {
                        print $indent .  '  id  ' . "\t: " . $key . ' => ' . $val . "\n";
                    }
                }
            }
        }
    }

    $level++;
    my @children = @{ $element->{children} };
    foreach (@children) {
        $self->_get_page($_, $level);
    }
}

sub _source_window_with_children {
    my ($self, $index) = @_;
    $index //= 0;

    my $window = $self->execute_script('UIATarget.localTarget().frontMostApp().windows()[' . $index . '].getTree()');
    if (scalar @{ $window->{children} }) {
        return $window;
    }
    else {
        return $self->_source_window_with_children(++$index);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Appium::Ios::CanPage - Display all interesting elements for iOS, useful during test authoring

=head1 VERSION

version 0.0804

=head1 METHODS

=head2 page

A shadow of L<arc|https://github.com/appium/ruby_console>'s page
command, this will print to STDOUT a list of all the interesting
elements on the current page along with whatever details are available
(name, label, value, etc).

    $appium->page;
    # UIAWindow
    #   UIATextField
    #     name          : IntegerA
    #     label         : TextField1
    #     value         : 5
    #     UIATextField
    #       name        : TextField1
    #       label       : TextField1
    #       value       : 5
    #   UIATextField
    #     name          : IntegerB
    #     label         : TextField2
    #     UIATextField
    #       name        : TextField2
    #       label       : TextField2
    # ...

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Appium|Appium>

=item *

L<Appium|Appium>

=item *

L<Appium::Ios::CanPage|Appium::Ios::CanPage>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/appium/perl-client/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
