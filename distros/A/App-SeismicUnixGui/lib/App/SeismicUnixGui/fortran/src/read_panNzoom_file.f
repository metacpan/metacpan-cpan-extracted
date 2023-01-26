      subroutine read_panNzoom_file(result,inbound)
         implicit none
!       read a configuration file

      integer :: result
      character (len=255) :: inbound, inbound_locked
      character (len=30) :: format1
      integer :: err_message, ready

      inbound_locked=trim(inbound)//"_locked"
      format1= "(I2)"

!      print *, 'read_layer_file, inbound is:', trim(inbound)
!      in case inbound is of a different, but shorter length in main

10     open(status='new',unit=26,file=inbound_locked,iostat=ready)

        if (ready.eq.0) then
         open(unit=27,file=trim(inbound),status='old',
     +    iostat=err_message)

!       check whether file opens data file
         if (err_message.eq.0) then

           read (27,format1) result
!          print *, 'read_panNzoom_file.f, result',result
          close (unit=31)

         else
!         print *, 'read_panNzoom_file.f, err_message=',err_message
!         print *, 'read_panNzoom_file.f, counter=',counter
!         rest a little before trying again
!         call sleep(1)
          go to 10
         end if
       else
         print *, 'lread_panNzoom_file.f,ocked, try again,read =',ready
         go to 10
       end if
!       remove lock file
11      close (status='delete',unit=26,iostat=err_message)
        if (err_message.ne.0) then
         go to 11
         print *, 'read_panNzoom_file.f, err_messg=',err_message
        end if
!       print *, 'read_panNzoom_file, result',result

      end subroutine read_panNzoom_file
