      subroutine read_option_file(result,inbound)
         implicit none

!       read option file with an integer number

      character (len=30) :: format1
      character (len=255) :: inbound, inbound_locked
      integer :: err_message, counter, ready
      integer :: result

      inbound_locked=trim(inbound)//"_locked"
      format1= "(I3)"

!      print *, 'read_option_file, inbound is:', trim(inbound)
!      in case inbound is of a different, but shorter length in main
!      inbound=inbound

!      open(unit=28,file=trim(inbound),status='old')
!       read (28,format1) result
!!       print *, 'read_option_file, result',result
!       close (unit=28)

!      create a temporary, new, lock file
10     open(status='new',unit=28,file=inbound_locked,iostat=ready)
!       print *, 'read_option_file.f,inbound_locked iostat:',ready
!       if (ready.eq.17) print *, 'locked, try again'
       if (ready.eq.0) then
        open(unit=29,file=trim(inbound),status='old',iostat=err_message)
!        counter = counter +1

!       check whether file opens data file
        if (err_message.eq.0) then

          read (29,format1) result

!        print *, 'read_option_file.f, result',result
         close (unit=29)

        else
!         print *, 'read_option_file.f, err_message=',err_message
!         print *, 'read_option_file.f, counter=',counter

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
!         print *, 'read_option_file.f, err_messg=',err_message
        end if

      end subroutine read_option_file
