# vim: set ts=4 sw=4 tw=78 et si:
#
package App::Checklist::Formatter;

use warnings;
use strict;

use version; our $VERSION = qv('v0.0.6');

use Class::Std;
{
    my %author : ATTR;
    my %title  : ATTR;
    my %checklist : ATTR;

    sub BUILD {
        my ($self,$ident,$args_ref) = @_;

        $checklist{$ident} = [];
    } # BUILD()

    sub read_vim_outliner {
        my ($self,$filename) = @_;
        my $OTL;
        my $vo = {
            curr_list  => $checklist{ident $self},
            lastindent => 0,
            last_items => [],
            last_lists => [],
        };

        if (open $OTL, '<', $filename) {
            # read in vim outliner
            while (<$OTL>) {
                next if /^\s*$/;
                if (/^(\s*):(.*)$/) {
                    $self->_vo_item_colon($vo,$1,$2);
                }
                elsif (/^(\s*);(.*)$/) {
                    $self->_vo_item_semicolon($vo,$1,$2);
                }
                elsif (/^(\s*)\[([x_])\]\s(.+)$/i) {
                    $self->_vo_item($vo,$1,$2,$3);
                }
                else {
                    croak("can't process line $.: $_");
                }
            }
            close $OTL;
        }
        else {
            die "can't open '$filename' for reading: $!";
        }
        return scalar @{$checklist{ident $self}};
    } # read_vim_outliner()

    sub _vo_down {
        my ($self,$vo,$indent,$check,$text) = @_;

        push @{$vo->{last_lists}}, $vo->{curr_list};
        $vo->{curr_list} = $vo->{curr_item}->{sublist} = [];
        $vo->{lastindent} = length $indent;
        $self->next_item($vo,$check,$text);
    } # _vo_down()

    sub _vo_item {
        my ($self,$vo,$indent,$check,$text) = @_;

        if (length($indent) > $vo->{lastindent}) {
            $self->_vo_down($vo,$indent,$check,$text);
        }
        elsif (length($indent) == $vo->{lastindent}) {
            $self->_vo_next_item($vo,$check,$text);
        }
        else {
            $self->_vo_up($vo,$indent,$check,$text);
        }
    } # _vo_item()

    sub _vo_item_colon {
        my ($self,$vo,$indent,$text) = @_;
        push @{$vo->{last_items} ->[length($indent)-1]->{comment}}, $text;
    } # _vo_item_colon()

    sub _vo_item_semicolon {
        my ($self,$vo,$indent,$text) = @_;

        if ($text =~ /^\s*author: (.+)/) {
            $author{ident $self} = $1;
        }
        if ($text =~ /^\s*checklist: (.+)/) {
            $title{ident $self} = $1;
        }
    } # _vo_item_semicolon()

    sub _vo_next_item {
        my ($self,$vo,$check,$text) = @_;

        $vo->{curr_item} = { text => $text, check => $check, comment => [], };
        push @{$vo->{curr_list}}, $vo->{curr_item};
        $vo->{last_items}->[$vo->{lastindent}] = $vo->{curr_item};
    } # _vo_next_item()

    sub _vo_up {
        my ($self,$vo,$indent,$check,$text) = @_;
    
        $vo->{lastindent} = length $indent;
        $vo->{curr_list} = pop @{$vo->{last_lists}};
        $#{$vo->{last_items}} = $vo->{lastindent};
        $self->next_item($vo,$check,$text);
    } # _vo_up()

} # package App::Checklist::Formatter

1; # Magic true value required at end of module
__END__

=head1 NAME

App::Checklist::Formatter - read vimoutliner files and format checklists

=head1 SYNOPSIS

  use App::Checklist::Formatter;

You probably want to use the program I<checklist-formatter>.

=head1 INTERFACE

=head2 Methods

=over

=item C<< read_vim_outliner($filename) >>

This method reads the file which name you provided in I<<$filename>>. This
file should be a text file formatted with vimoutliner.

=back

=head1 SEE ALSO

L<checklist-formatter>
F<www.vimoutliner.org>

=head1 AUTHOR

Mathias Weidner, C<< mamawe@cpan.org >>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Mathias Weidner

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.
