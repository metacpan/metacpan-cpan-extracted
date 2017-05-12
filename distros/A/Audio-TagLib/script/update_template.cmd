@echo off
goto beginning
  *
  * It is what it is, you can do with it as you please. [respect credits]
  *
  * Just don't blame me if it teaches your computer to smoke!
  * 
  *  -Enjoy
  *  fh :)_~
  * 
  * Created 10/14/2013
  *
:beginning

if exist script\update_template.cmd (
  for /f %%a IN ('dir /b script\update_template\*.pl') do perl script\update_template\%%a
) else (
  echo Usage: Must be run in the Audio-TagLib base directory.
)

