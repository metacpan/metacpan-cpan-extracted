package App::tonematch;


use 5.006;
use strict;
use warnings;

=encoding UTF-8

=head1 NAME

App::tonematch - A script to test the tone perception of your ears.

=head1 VERSION

Version 0.002

=cut

$App::tonematch::VERSION=0.002;

=head1 SYNOPSIS

    $ tonematch

=head1 DESCRIPTION

This is a script designed to test the accuracy of the tone
discrimination of the users hearing. Two tones are produced and the user
must vary one of them until both match. The script repeatedly
generates a tone with a randomly 
chosen unknown frequency and sends it through your earphones to one of your
ears to be compared with a tone of a frequency under the user's
control that is sent to his other ear. When the user believes the
tones agree the test continues with a new random tone. The output of
the program is a text file with the chosen frequencies and the
discrepancies between both ears. The user can the plot the results with an
external program or process them with whatever tool he choses.

=head1 INSTRUCTIONS

Test the accuracy of your hearing.

Use your headphones/earphones.

Press the (Re)init button to initialize a random tone.

Choose a file to save the results.

Repeatedly, press the Reference and Current buttons while
modifying the frequency dials until you believe both tones
match. You might want to set the volume for each channel. If the tone
is inaudible (maybe due to a too high or low frequency), you can
change it by Reiniting. 

After matching a tone, Reinit and repeat the process until you get
tired, and then Stop. 

You may Peek (but you shouldn't) to find out how
you are doing.  

The result is a text file with three columns of data: the target frequency,
the matching frequency and the difference in semi-tones. After the
test is concluded, this file may be processed with external
tools. For example, the may be plotted with *gnuplot.*



=head1 AUTHOR

W. Luis Mochán, Instituto de Ciencias Físicas, UNAM, México
C<mochan@fis.unam.mx> 

=head1 ACKNOWLEDGMENTS

This work was partially supported by DGAPA-UNAM under grants IN108413
and IN113016.   

=cut

1;
