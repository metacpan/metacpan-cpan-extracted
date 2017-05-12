# ----------------------------------------------------------------------------------------------------------
#!/bin/sh
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, htmldoc.sh for ASNMTAP
# ---------------------------------------------------------------------------------------------------------
# Compatible with HTMLDOC v1.8.27 from http://www.htmldoc.org/ or http://www.easysw.com/htmldoc
#
# http://${SERVER_NAME}/asnmtap/cgi-bin/htmldoc.sh/asnmtap/cgi-bin/detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl?$QUERY_STRING
#                      <--------------------------------------- ${PATH_INFO} -------------------------------------->
# ----------------------------------------------------------------------------------------------------------

# The "options" variable contains any options you want to pass to HTMLDOC.
options='--bodyimage /opt/asnmtap/applications/htmlroot/img/logos/bodyimage.gif --charset iso-8859-1 --format pdf14 --size A4 --landscape --browserwidth 1280 --top 10mm --bottom 10mm --left 10mm --right 10mm --fontsize 10.0 --fontspacing 1.2 --headingfont Helvetica --bodyfont Helvetica --headfootsize 10.0 --headfootfont Helvetica --embedfonts --pagemode fullscreen --permissions no-copy,print --no-links --color --quiet --webpage --header ... --footer ...'

HTMLDOC_NOCGI=1; export HTMLDOC_NOCGI

# Tell the browser to expect a PDF file ...
echo "Content-Type: application/pdf"
echo ""
echo "Content-disposition: attachment; filename=GeneratedReport.pdf"
echo ""
echo ""

# Run HTMLDOC to generate the PDF file ...
htmldoc -t pdf $options http://${SERVER_NAME}:${SERVER_PORT}${PATH_INFO}?$QUERY_STRING

# ----------------------------------------------------------------------------------------------------------
