      subroutine write_yes_no_file(yes_or_no,outbound)
         implicit none
      character*5 yes_or_no
      character (len=255) :: outbound, outbound_locked
      character (len=30)  :: format1
      integer :: err_message, counter, ready

!      print *, 'write_yes_or_no_file, outbound is: ', outbound

      outbound_locked=trim(outbound)//"_locked"
      format1= "(A)"

  !      create a temporary, new, lock file
10     open(status='new',unit=28,file=outbound_locked,iostat=ready)
!       print *, 'read_option_file.f,inbound_locked iostat:',ready
!       if (ready.eq.17) print *, 'locked, try again'

      if (ready.eq.0) then
        open (2,file=trim(outbound),status='old',iostat=err_message)
!        counter = counter +1

!       check whether file opens data file
       if (err_message .eq. 0) then

        write (2,format1) trim(yes_or_no)
!        print *, 'write_yes_or_no_file, yes_or_no: ',trim(yes_or_no)
        close (unit=2)

       else
        print *, 'write_yes_no_file.f, err_message=',err_message

!         rest a little before trying again
!         call sleep(1)
         go to 10
        end if
       else
!         print *, 'read_option_file.f,locked, try again,read =',ready
          go to 10
       end if
 !       remove lock file
11      close (status='delete',unit=28,iostat=err_message)
        if (err_message.ne.0) then
         go to 11
         print *, 'write_yes_no_file.f, err_messg=',err_message
        end if

      end subroutine write_yes_no_file
