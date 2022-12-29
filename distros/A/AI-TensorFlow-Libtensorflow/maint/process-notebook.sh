#!/bin/sh

set -eu

## Requirements:
##
## perl, python, sponge, grep, jq
##
## Perl deps:
##
## $ cpanm Devel::IPerl Perl::PrereqScanner::NotQuiteLite Cwd Path::Tiny
##
## Python deps:
##
## $ pip3 install jupyter

SRC="notebook/InferenceUsingTFHubMobileNetV2Model.ipynb";
DST="lib/AI/TensorFlow/Libtensorflow/Manual/InferenceUsingTFHubMobileNetV2Model.pod";
rm $DST || true;

if grep -C5 -P '\s+\\n' $SRC -m 2; then
	echo "Notebook $SRC has whitespace"
	exit 1
fi

## Run the notebook
jupyter nbconvert --execute --inplace $SRC

## Clean up metadata (changed by the previous nbconvert --execute)
## See more at <https://timstaley.co.uk/posts/making-git-and-jupyter-notebooks-play-nice/>
jq --indent 1     '
    del(.cells[].metadata | .execution)
    ' $SRC | sponge $SRC

### Notice about generated file
echo "# PODNAME: $(basename $SRC .ipynb)\n\n" | sponge -a $DST
echo "## DO NOT EDIT. Generated from $SRC using $0.\n" | sponge -a $DST

## Add code to $DST
jupyter nbconvert $SRC --to script --stdout | sponge -a $DST;

## Add
##   __END__
##
##   =pod
##
perl -E 'say qq|__END__\n\n=pod\n\n|' | sponge -a $DST;

## Add POD
iperl nbconvert.iperl $SRC  | sponge -a $DST;

## Edit to local section link (Markdown::Pod does not yet recognise this).
perl -pi -E 's,\QL<CPANFILE|#CPANFILE>\E,L<CPANFILE|/CPANFILE>,g' $DST

## Add
##   =head1 CPANFILE
##
##     requires '...';
##     requires '...';
scan-perl-prereqs-nqlite --cpanfile $DST | perl -M5';print qq|=head1 CPANFILE\n\n|' -plE '$_ = q|  | . $_;' | sponge -a $DST ;

## Check output (if on TTY)
if [ -t 0 ]; then
	perldoc $DST;
fi

## Check and run script in the directory of the original (e.g., to get data
## files).
perl -c $DST && perl -MCwd -MPath::Tiny -E '
	my $nb = path(shift @ARGV);
	my $script = path(shift @ARGV)->absolute;
	chdir $nb->parent;
	do $script;
	' $SRC $DST
