#!/bin/bash

# starting variable definitions
starting_points='/home /'
priority_level='-O3'
file='f'
case=1
repeat=1
continue=0
default_answer="y"

# see if a global variable is set
# SeismicUnixGui_script is a global variable for locating the script folder

echo -e "\n\tGLOBAL VARIABLES*********************"
 if [ -z "${SeismicUnixGui_script}" ]; then
	
 	echo  " Global variable SeismicUnixGui_script should be set"
 	echo " e.g.,in .bashrc you should have a line as follows: "
 	echo -e " export SeismicUnixGui_script=/Location/of/script/folder \n"
 	
 else
 	echo " "
        echo -e " Global variable SeismicUnixGui_script currently is:\
 ${SeismicUnixGui_script}\n"
 fi
 
# Parameters to find a needed file
# find -print0 option produces null delimited strings so spaces, 
# tabs and carriage return in file names are preserved safely.

# restart a search
choice=1
ans=0
hint_ans=''
Afile2find="post_install_fortran_compile.pl"
# read the list of files and their paths

echo -e " Please be patient."
echo -e " Looking for scripts to compile fortran and C code  ...\n"
echo -e " Hint: Choose a path with \"bin/$Afile2find\" in its name."
echo -e " A local installation also has \"perl5/bin\" in the path."
echo -e " Ignore the case with \"blib\" in its path.\n"
readarray -d '' -t list < <(find $starting_points -type $file -name $Afile2find -print 2>/dev/null )
length=${#list[@]}
echo -e "Found $length post-installation script(s) to run:\n"

for each in ${list[@]}
do
    echo "Case $case:   $each"
    ((case=case+1))
    
    # quiet: -q; ignorable cases
     echo $each | grep -q blib
     ((ans=$?))
    
     if [[ $ans == 0 ]]; then  
       echo "Ignore"   
     elif [[ $ans == 1 ]]; then    
       hint_ans=$each      
     else 
       echo "unexpected L 65"
     fi
    
done

while [ $choice == $repeat ]; do
	# echo "choice is $choice and repeat is $repeat"
	echo -e "\nEnter first script name (with Full Path),\n or use the default: [$hint_ans]\n"
	read -r -p "Enter a name or only Hit Return:" input

	# check for content
	if [ -z "$input" ]; then
	   script_name=$hint_ans
	else
	   script_name=$input
	fi

	echo -e "OK, we will use: $script_name\n"
	read -p "Please confirm (y/n)? [$default_answer]:" answer

	# check for content
	if [ -z "$answer" ]; then
	   ((choice=$continue))	 		     
	elif [[ "$answer" == "n" ]]; then
	   echo "choicen=$choice"	  
	elif [[ "$answer" == "y" ]]; then
	    ((choice=$continue))
	else
	    echo "uenxpected L 92"
	fi

 done
echo -e "\n perl $script_name\n"
perl $script_name

# finished with programs in Fortran

c_script_name=$(echo $script_name | sed -e 's/fortran/c/')
# Now, for C programs -- read the list of files and their paths
echo -e "\nNow, looking for scripts to compile C code  ..."
echo -e "\nNext script name=$c_script_name"
echo "Looking for $c_script_name to compile  C code  ..."
perl $c_script_name

# env_script_name=$(echo $script_name | sed -e 's/fortran_compile/env/')
# echo -e "environment script=$env_script_name"
# sudo perl $env_script_name
