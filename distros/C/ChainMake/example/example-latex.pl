#!/usr/bin/perl

use strict;
use lib '..';
use ChainMake::Functions ':all';

target 'example.tex', (
    timestamps   => ['$t_name'],
    handler => sub {
        my $t_name=shift;
        open OUT,">",$t_name or print "Can't write $t_name: $!" && return 0;
        print OUT get_tex();
        close OUT;
        1;
    }
);

target 'example.dvi', (
    timestamps   => ['$t_name'],
    requirements => ['$t_base.tex'],
    handler => sub {
        my ($t_name,$t_base,$t_ext)=@_;
        my $rerun=1;
        my ($multiply_defined_labels,$undefined_references,$font_shapes_not_available);
        while ($rerun) {
	        print "> latex -interaction=batchmode $t_base.tex\n";
	        $rerun=0;
	        $multiply_defined_labels=0;
	        my $output=`latex $t_base.tex`;
            $rerun=1 if ($output =~ /LaTeX Warning: Label\(s\) may have changed/);
	        $multiply_defined_labels=1 if ($output =~ /LaTeX Warning: There were multiply-defined labels/);
	        $undefined_references=1 if ($output =~ /LaTeX Warning: There were undefined references/);
	        $font_shapes_not_available=1 if ($output =~ /LaTeX Font Warning: Some font shapes were not available/)
        }
        print STDOUT "Warning: There were undefined references.\n" if ($undefined_references);
        print STDOUT "Warning: Some font shapes were not available.\n" if ($font_shapes_not_available);
        print STDOUT "Warning: Multiply-defined labels.\n" if ($multiply_defined_labels);
        1;
    }
);

target ['example.ps','another.ps'], (
    timestamps   => ['$t_name'],
    requirements => ['$t_base.dvi'],
    handler => sub {
        my ($t_name,$t_base,$t_ext)=@_;
        execute_system(
            All => "dvips -P pdf -q -t a5 $t_base.dvi",
        );
    }
);

target qr/^[^\.]+\.pdf$/, (
    timestamps   => ['$t_name'],
    requirements => ['$t_base.ps'],
    handler => sub {
        my ($t_name,$t_base,$t_ext)=@_;
        execute_system(
            All => "ps2pdf $t_base.ps $t_base.pdf",
        );
    }
);

target 'clean', (
    handler => sub {
        unlink qw/example.tex example.aux example.dvi example.log/;
        1;
    }
);

target 'realclean', (
    requirements => ['clean'],
    handler => sub {
        unlink qw/example.pdf example.ps/;
        1;
    }
);

target [qw/all All/], requirements => ['example.pdf','clean'];

chainmake(@ARGV);


sub get_tex { <<'LATEX'
\documentclass[10pt,a5paper]{scrbook}        % oder was auch immer
\usepackage{ngerman}
\usepackage[latin1]{inputenc}   % Umlaute in der Eingabe
\usepackage{graphicx}           % und andere Pakete die man braucht...
\begin{document}
\title{Bürgerliches Gesetzbuch}
\maketitle

\newcommand{\sect}[3]{\noindent\textbf{#1~#2} #3\par\vspace{1em}}
\newcommand{\subsect}[1]{#1\par}

\part*{Buch 1\\Allgemeiner Teil}
\chapter*{Abschnitt 1\\Personen}
\section*{Titel 2\\Juristische Personen}
\subsection*{Untertitel 1\\Vereine}
\subsubsection*{Kapitel 1\\Allgemeine Vorschriften}

\sect{\S\,21}{Nichtwirtschaftlicher Verein}{

\subsect{Ein Verein, dessen Zweck nicht auf einen wirtschaftlichen Geschäftsbetrieb gerichtet ist, erlangt Rechtsfähigkeit durch Eintragung in das Vereinsregister des zuständigen Amtsgerichts.}
}

\sect{\S\,22}{Wirtschaftlicher Verein}{

\subsect{\textsuperscript{1}Ein Verein, dessen Zweck auf einen wirtschaftlichen Geschäftsbetrieb gerichtet ist, erlangt in Ermangelung besonderer reichsgesetzlicher Vorschriften Rechtsfähigkeit durch staatliche Verleihung. \textsuperscript{2}Die Verleihung steht dem Bundesstaate zu, in dessen Gebiet der Verein seinen Sitz hat.}
}

\sect{\S\,26}{Vorstand; Vertretung}{

\subsect{(1) \textsuperscript{1}Der Verein muss einen Vorstand haben. \textsuperscript{2}Der Vorstand kann aus mehreren Personen bestehen.}
\subsect{(2) \textsuperscript{1}Der Vorstand vertritt den Verein gerichtlich und außergerichtlich; er hat die Stellung eines gesetzlichen Vertreters. \textsuperscript{2}Der Umfang seiner Vertretungsmacht kann durch die Satzung mit Wirkung gegen Dritte beschränkt werden.}
}

\end{document}
LATEX
}


__END__

=head1 example-latex.pl

This is an example script that uses L<ChainMake>. Some documentation would be nice here.
Please see the code for now.

=head1 AUTHOR/COPYRIGHT

This is C<$Id: example-latex.pl 1232 2009-03-15 21:26:53Z schroeer $>.

Copyright 2009 Daniel Schröer (L<schroeer@cpan.org>). Any feedback is appreciated.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
=cut  
