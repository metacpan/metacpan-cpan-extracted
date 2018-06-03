
# It correctly works on either of BASH or ZSH.
script_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

# Adding the current directon to the PATH variable. 
PATH=$script_dir:$PATH

# The folwing 5 lines are to add the sub_directories to PATH.
# You may delete the following intentinally if it is necessary.
for subdir in $script_dir/* 
do 
  [ -d $subdir ] || continue  
  PATH=$subdir:$PATH 
done 


