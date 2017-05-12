#!/bin/bash

echo Content-type: text/html
echo -e "\r\n\r\n"

A="Test bash script"
/bin/cat << EOM
<HTML>
<HEAD><TITLE>$A</TITLE>
</HEAD>
<BODY bgcolor="#cccccc" text="#000000">
<HR SIZE=5>
<H1>Testing </H1>
<HR SIZE=5>
<P>
<SMALL>
<PRE>
EOM

exit 0
