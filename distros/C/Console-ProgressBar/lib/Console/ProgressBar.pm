package Console::ProgressBar;
use 5.008001;
use strict;
use warnings;
use utf8;

our $VERSION = "1.01";

sub new {
    my ($class,$_title,$_maxValue,$configuration) = @_;
    my $this = {
        _index => 0,
        title => $_title,
        titleMaxSize => 30,
        maxValue => $_maxValue,
        length => 20,
        segment => '#'
    };
    bless($this,$class);

    if(defined($configuration)) {
        my %conf = %{ $configuration };
        foreach my $parameter (keys %conf) {
            $this->{$parameter} = $conf{$parameter};
        }
    }

    return $this;
}

sub _calculateCurrentValue {
    my($this) = @_;
    return int( ( $this->{_index} / $this->{maxValue} ) * 100 );
}

sub _getGraphicBars {
    my($this,$percentage) = @_;
    my $bars = "";
    my $nbrBars = int( ($percentage / 100) * $this->{length} );
    $bars = $this->{segment} x $nbrBars;

    return $bars; 
}

sub reset {
    my ($this) = @_;
    $this->{_index} = 0;
    
    return $this;
}

sub setTitle {
    my ($this,$title) = @_;
    $this->{title} = $title;

    return $this;
}

sub setIndex {
    my ($this,$value) = @_;
    $this->{_index} = $value;

    return $this;
}

sub getIndex {
    my ($this)= @_;
    return $this->{_index};
}

sub next {
    my ($this) = @_;
    if( $this->{_index} < $this->{maxValue} ) {
        $this->{_index}++;
    }
    return $this;
}

sub back {
    my ($this) = @_;
    if($this->{_index} > 0) {
        $this->{_index}--;
    }
    return $this;
}

sub render {
    my ($this) = @_;

    my $percentage = $this->_calculateCurrentValue();
    my $bars = $this->_getGraphicBars($percentage);

    my $progressBar = sprintf("%-$this->{titleMaxSize}s [%-$this->{length}s] %d%%",$this->{title},$bars,$percentage);
    print "$progressBar\r";
    $|++;
}

1;
__END__

=encoding utf-8

=head1 NAME

Console::ProgressBar - A simple progress bar for Perl console applications

=head1 SYNOPSIS

    use Console::ProgressBar;

=head1 DESCRIPTION

Console::ProgressBar is a simple progress bar for Perl console applications.

    use Console::ProgressBar;

    # create a progress bar for a task with 20 steps
    my $p = Console::ProgressBar->new('Writing files',20);

    # for each step done, the progress bar index is incremented
    # and the progress bar is displayed at the current cursor position
    for(my $i=1; $i <= 20; $i++) {
        $p->next()->render();
    }

The progress bar displays a title that describe the task and the percentage of completion.

    Writing Files       [##########          ] 50%

=head2 How to install ?

If you want install C<Console::ProgressBar> directly from the git repository, please use the following command :

    cpanm https://codeberg.org/auverlot/Console-ProgressBar.git

=head2 How to control the progress bar state ?

=head3 next()

The next() method indicates that a step is done.

=head3 back()

The back() method indicates that the last step must be canceled. The internal index of the progress bar is decremented.

=head3 reset()

The reset() method sets the internal index to 0. For the progress bar, none step has be done. The percentage of completion is 0%.

=head3 setIndex($aValue)

The setIndex() method set the internal index to the specified value (between 0 and the number of steps).

=head2 How to customize the progress bar ?

=head3 setTitle($aTitle)

The setTitle() method changes the title of the progress bar. You can easily displaying a contextual information about the step in progress.

=head3 Change the appearance

The builder has an optional parameter. It's a hash to change the default values of :

=over

=item * the string that contains the title (C<titleMaxSize>), 

=item * the number of characters used to represent the progression (C<length>)

=item * the caracter used to fill the progress bar (C<segment>). 

=back

        titleMaxSize            length
    <------------------> <------------------>
    Writing Files       [##########          ] 50%
                            ^
                          segment

The following example creates a custom progress bar :

    use Console::ProgressBar;

    my $p = Console::ProgressBar->new('Writing files',20, {
        titleMaxSize => 40,
        length => 40,
        segment => '='
    });

=head1 LICENSE

Copyright (C) Auverlot Olivier.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Auverlot Olivier E<lt>oauverlot@cpan.orgE<gt>

=cut

