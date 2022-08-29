#!/bin/bash

read -a color < <( ansiecho -S ZE K/544 K/454 K/445 )

reset=${color[0]}

echo "${color[1]} COLOR 1 ${reset}"
echo "${color[2]} COLOR 2 ${reset}"
echo "${color[3]} COLOR 3 ${reset}"

for ((i = 1; i < ${#color[@]}; i++)); do
    echo "${color[$i]} COLOR $i ${reset}"
done

ansiecho -c K/544 " COLOR 1 "
ansiecho -c K/454 " COLOR 2 "
ansiecho -c K/544 " COLOR 3 "

read ZE C1 C2 C3 < <( ansiecho -S ZE K/544 K/454 K/445 )

echo "${C1} COLOR 1 ${ZE}"
echo "${C2} COLOR 2 ${ZE}"
echo "${C3} COLOR 3 ${ZE}"

array[0]=$(ansiecho -s R)
array[1]=$(ansiecho -s ZE)
echo "${array[0]} NAME ${array[1]}"

declare -A hash
hash[NAME]=$(ansiecho -s R)
hash[ZE]=$(ansiecho -s ZE)
echo "${hash[NAME]} NAME ${hash[ZE]}"
