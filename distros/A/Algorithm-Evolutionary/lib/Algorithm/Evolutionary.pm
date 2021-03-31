package Algorithm::Evolutionary;

use Carp qw(croak);

our $VERSION = '0.82.1'; # Later than 1st GitHub version

# Preloaded methods go here.

# A bit of importing magic taken from POE
sub import {
  my $self = shift;

  my @modules  = grep(!/^(Op|Indi|Fitness)$/, @_);

  my $package = caller();
  my @failed;

  # Load all the others.
  foreach my $module (@modules) {
    my $code = "package $package; use Algorithm::Evolutionary::$module;";
    # warn $code;
    eval($code);
    if ($@) {
      warn $@;
      push(@failed, $module);
    }
  }

  @failed and croak "could not import qw(" . join(' ', @failed) . ")";
}

1;
__END__

=encoding utf8

=head1 NAME

Algorithm::Evolutionary - Perl module for performing paradigm-free evolutionary algorithms. 

=head1 SYNOPSIS

  #Short way of loading a lot of modules, POE-style
  use Algorithm::Evolutionary qw( Op::This_Operator
                                  Individual::That_Individual
                                  Fitness::Some_Fitness); 

  # other modules with explicit importation
  use Algorihtm::Evolutionary::Utils (this_util that_util);   

=head1 DESCRIPTION

C<Algorithm::Evolutionary> is a set of classes for doing object-oriented
evolutionary computation in Perl. Why would anyone want to do that
escapes my knowledge, but, in fact, we have found it quite useful for
our own purposes. Same as Perl itself.

The main design principle of L<Algorithm::Evolutionary> is I<flexibility>: it
should be very easy to create your own evolutionary algorithms using this library, and it should be
also quite easy to program what's already there in the evolutionary
computation community. Besides, the library classes should have
persistence provided by YAML.

The module allows to create simple evolutionary algorithms, as well
as more complex ones, that interface with databases or with the
web. 

=begin html

<p>The project has been, from version 0.79, moved to
<a href='http://github.com/JJ/Algorithm-Evolutionary'>GitHub</a>. Latest aditions, and
nightly updates, can be downloaded from there before they are uploaded
to CPAN. That page also hosts the mailing list, as well as bug
reports, news, updates, work in progress, lots of stuff.</p>

<p>In case the examples are hidden somewhere in the <code>.cpan</code> directory,
    you can also download them from <a
    href='https://github.com/JJ/Algorithm-Evolutionary/tree/master/examples'>the
    git repository</a>. You can also get help from the <a
href='https://github.com/JJ/Algorithm-Evolutionary/issues'>project
issues</a>.</p> 

<p>It might be also helpful for you to check out <a
href='http://arxiv.org/abs/0908.0516'>Still doing evolutionary
algorithms with Perl</a>, a gentle introduction to evolutionary
algorithms in general and working with them using this module in particular.</p>

<p>I have used this library continously for my research all these year, and
any search will return a number of papers; a journal article is
already submitted, but meanwhile if you use it for any of your
research, I would be very grateful if you quoted papers such as these
(which are, of course, available under request or from your friendly
 university librarian):</p>

=end html

 @article {springerlink:10.1007/s00500-009-0504-3,
   author = {Merelo Guervós, Juan-Julián and Castillo, Pedro and Alba, Enrique},
   affiliation = {Universidad de Granada Depto. Arquitectura y Tecnología de Computadores, ETS Ingenierías Informática y Telecomunicaciones Granada Spain},
   title = {Algorithm::Evolutionary, a flexible Perl module for evolutionary computation},
   journal = {Soft Computing - A Fusion of Foundations, Methodologies and Applications},
   publisher = {Springer Berlin / Heidelberg},
   issn = {1432-7643},
   keyword = {Computer Science},
   pages = {1091-1109},
   volume = {14},
   issue = {10},
   url = {http://dx.doi.org/10.1007/s00500-009-0504-3},
   note = {10.1007/s00500-009-0504-3},
   year = {2010}
 }

or

 @InProceedings{jj:2008:PPSN,
   author =	"Juan J. Merelo and  Antonio M. Mora and Pedro A. Castillo
                 and Juan L. J. Laredo and Lourdes Araujo and Ken C. Sharman
                 and Anna I. Esparcia-Alcázar and Eva Alfaro-Cid
                 and Carlos Cotta",
   title =	"Testing the Intermediate Disturbance Hypothesis: Effect of
                 Asynchronous Population Incorporation on Multi-Deme
                 Evolutionary Algorithms",
   booktitle =	"Parallel Problem Solving from Nature - PPSN X",
   year = 	"2008",
   editor =	"Gunter Rudolph and Thomas Jansen and Simon Lucas and
		  Carlo Poloni and Nicola Beume",
   volume =	"5199",
   series =	"LNCS",
   pages =	"266-275",
   address =	"Dortmund",
   month =	"13-17 " # sep,
   publisher =	"Springer",
   keywords =	"genetic algorithms, genetic programming, p2p computing",
   ISBN = 	"3-540-87699-5",
   doi =  	"10.1007/978-3-540-87700-4_27",
   size = 	"pages",
   notes =	"PPSN X",
 }

=begin html

<p>or the ArXiV paper linked above.</p>

<p>Some information on this paper and instructions for downloading the code used in it can
be found in <a
href='http://nohnes.wordpress.com/2008/09/21/paper-on-performance-of-asynchronous-distributed-evolutionary-algorithms-available-online/'>our
group blog</a>.</p> 

=end html

=head1 Examples

There are a few examples in the C<examples> subdirectory, which should
have been included with your CPAN bundle. For instance, check out
C<tide_float.pl>, an example of floating point vector optimization, or
C<cd examples; run_easy_ga.pl p_peaks.yaml>, which should run an
    example of a
simple GA on the P_Peaks deceptive function.

Some other examples are installed: check out L<tide_bitstring.pl>,
    L<tide_float.pl> and L<canonical-genetic-algorithm.pl>, which you
    can run and play with to get a taste of what EA programming is
    like, and then ammend, add and modify at leisure to create your
    own evolutionary algorithms. For a GUI example, check
    L<rectangle-coverage.pl>, which uses L<Tk> to show the population
    and its evolution. You will need to install the required modules,
    however, since it needs additional ones to those required by this
    module. 


=head1 DISCUSSION, FEATURE REQUESTS

Head to the CPAN forum for this module:
L<http://www.cpanforum.com/dist/Algorithm-Evolutionary> 

=head1 BUGS?

Have you found any bugs? Use the CPAN tracker to inform about them
(L<http://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Evolutionary>)
or email the author (below) or
C<bug-algorithm-evolutionary@rt.cpan.org>. 

=head1 AUTHOR

=begin html

Main author and developer is J. J. Merelo, jmerelo (at) geneura.ugr.es
who blogs at <a href='http://blojj.blogalia.com'>BloJJ</a> and
twitters at <a
href='http://twitter.com/jjmerelo'>twitter.com/jjmerelo</a>. There have
also been some contributions from Javi García, fjgc (at) decsai.ugr.es
and Pedro Castillo, pedro (at) geneura.ugr.es. 

Patient users that have submitted bugs include <a
href='http://barbacana.net'>jamarier</a>, <a
href='http://leandrohermida.com'>Leandro Hermida</a>, Jérôme Quélin,
Mike Gajewski and Cristoph Meissner. <a href='http://alexm.org'>Alex
Muntada</a>, from the <a href='http://barcelona.pm.org/'>Barcelona
Perl Mongers</a>, helped me solve a problem with the Makefile.PL.

Bug reports (and patches), requests and any kind 
of comment are welcome.

=end html

=head1 SEE ALSO

If you are just looking for a plain vanilla genetic algorithm for
didactic purposes, check also L<Algorithm::Evolutionary::Simple>,
which does the job in a straight fashion and can be used easily for
demos or adapting it to external fitness functions. 

=over

=item L<Algorithm::Evolutionary::Op::Base>.

=item L<Algorithm::Evolutionary::Individual::Base>.

=item L<Algorithm::Evolutionary::Fitness::Base>.

=item L<Algorithm::Evolutionary::Experiment>.

=item L<Algorithm::Evolutionary::Run>.

=item L<Algorithm::Evolutionary::Op::CanonicalGA>.


=item L<POE::Component::Algorithm::Evolutionary> if you want to mix
evolutionary algorithms with anything else easily.

=item L<Algorithm::MasterMind::Evolutionary> uses this library to find
the solution to the MasterMind Puzzle.

You might also be interested in one of the other perl GA and
evolutionary computation modules out there, such as
L<AI::Genetic::Pro>.

=back 

=cut

=head1 Copyright
  
This file is released under the GPL. See the LICENSE file included in this distribution,
or go to http://www.fsf.org/licenses/gpl.txt

=cut
