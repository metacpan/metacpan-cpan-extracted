#!/bin/bash
# COPYRIGHT
VERSION='0.006_000'

# https://stackoverflow.com/questions/4638874/how-to-loop-through-a-directory-recursively-to-delete-files-with-certain-extensi
# [To work around the failure] if there are spaces in filenames, ... temporarily [set] the IFS (internal field seperator) to the newline character. This also fails if there are wildcard characters \[?* in the file names. You can work around that by temporarily disabling wildcard expansion (globbing).

# default to current directory
if (( $# == 0 ))
then
    PYTHON_DIR=.
    echo "Defaulting to current directory"
elif (( $# == 1 ))
then
    PYTHON_DIR=$1
    OFFSET=0
    P2P_LOG_FILE=/tmp/p2p_multi.out
    P2P_SCRIPT_FILE=/tmp/p2p_multi.sh
    echo "Setting directory to " $PYTHON_DIR
elif (( $# == 2 ))
then
    PYTHON_DIR=$1
    OFFSET=$2
    P2P_LOG_FILE=/tmp/p2p_multi_$OFFSET.out
    P2P_SCRIPT_FILE=/tmp/p2p_multi_$OFFSET.sh
    echo "Setting directory to" $PYTHON_DIR " with offset" $OFFSET
else
    echo "Please provide no more than one directory path string and one offset integer at a time"
    exit
fi

# reset contents of output log & script files
rm -i $P2P_LOG_FILE
rm -i $P2P_SCRIPT_FILE

IFS=$'\n'; set -f

# normal:  .py 
# special: .pyx
# not yet supported: .pyx.tp .pxd .pxi
I=0
TRANSLATED_COUNT=0
for PYTHON_FILE in $(find $PYTHON_DIR -name '*.py' -or -name '*.pyx' | sort)
do

    I=$((I+1)) 
    if (( $I < $OFFSET ))
    then
        echo "Python file '$PYTHON_FILE' less than offset; SKIPPING"
        continue
    fi

    unset PERL_FILE
    eval $( bin/dev/python_file_path_to_perl_file_path.pl $PYTHON_FILE ONLY_PRINT_PERL_FILE_PATH )
    echo "have #$I PYTHON_FILE='$PYTHON_FILE'"
    echo "have #$I   PERL_FILE='$PERL_FILE'"
#    exit

    # check if PERL_FILE is unset or empty string
    if [ -z $PERL_FILE ]
    then
        echo "Python file '$PYTHON_FILE' error; SKIPPING"
#        echo "Python file '$PYTHON_FILE' error; DYING"
#        exit
    # check if PERL_FILE is a file that exists
    elif [ -f "$PERL_FILE" ]
    then 
        echo "Python file '$PYTHON_FILE' done; SKIPPING"
    else
        TRANSLATED_COUNT=$((TRANSLATED_COUNT+1)) 
        echo "Python file '$PYTHON_FILE' not done; TRANSLATING"
#       echo      "$ ./bin/python_to_perl $PYTHON_FILE >> $P2P_LOG_FILE 2>&1"  # echo into STDOUT
        echo "echo $ ./bin/python_to_perl $PYTHON_FILE  #$TRANSLATED_COUNT;$I">> $P2P_SCRIPT_FILE  # echo into script
        echo "echo $ ./bin/python_to_perl $PYTHON_FILE >> $P2P_LOG_FILE 2>&1" >> $P2P_SCRIPT_FILE  # echo into log file
        echo        "./bin/python_to_perl $PYTHON_FILE >> $P2P_LOG_FILE 2>&1" >> $P2P_SCRIPT_FILE  # run  into log file
#                    ./bin/python_to_perl $PYTHON_FILE >> $P2P_LOG_FILE 2>&1   # run  into STDOUT
    fi
done

unset IFS; set +f
