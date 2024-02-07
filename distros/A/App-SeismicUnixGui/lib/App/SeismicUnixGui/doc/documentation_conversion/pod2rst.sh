pod2html --infile suop.pm --outfile suop.html
pod2markdown < suop.pm > suop.markdown
pandoc -o suop.rst suop.html
pandoc -o suop_2.rst suop.markdown
