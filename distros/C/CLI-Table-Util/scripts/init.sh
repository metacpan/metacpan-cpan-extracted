
# Either of BASH or ZSH is OK.
script_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

PATH=$script_dir:$PATH
#for subdir in eg stats trivials lines subtotal tabulate 
for subdir in $script_dir/* 
  do 
  [ -d $subdir ] || continue  
  PATH=$subdir:$PATH 
done 


