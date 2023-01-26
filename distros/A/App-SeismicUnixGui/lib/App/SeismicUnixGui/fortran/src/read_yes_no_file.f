      subroutine read_yes_no_file(result,inbound)
         implicit none
!       read a configuration file

      logical :: result
      character (len=255) :: inbound, inbound_locked
      character (len=30)  :: format1
      character (len=80)  :: change
      integer :: err_message, counter, ready

      inbound_locked=trim(inbound)//"_locked"
      format1= "(A)"
!      in case definition in main is slightly different
       change = 'no'
!      print *, 'read_yes_no_file.f,inbound is:',inbound
!      in case inbound is of a different, but shorter length in main
!      inbound=inbound

!      create a temporary, new, lock file
10     open(status='new',unit=11,file=inbound_locked,iostat=ready)
!        print *, 'read_yes_no_file.f,inbound_locked, unlocked:',ready

       if (ready.eq.0) then
        open(unit=12,file=inbound,status='old',iostat=err_message)
!        counter = counter +1

!       check whether file opens data file
        if (err_message.eq.0) then

         read (12,format1) change

         if (change == 'yes') then
          result = .TRUE.
         else
          result = .FALSE.
         end if

!        print *, 'read_yes_no_file.f, change:',change
!        print *, 'read_yes_no_file.f, result',result
         close (unit=12)

        else
!         print *, 'read_yes_no_file.f, err_message=',err_message
!         print *, 'read_yes_no_file.f, counter=',counter
!         rest a little before trying again
!         call sleep(1)
         go to 10
        end if
       else
!        print *, 'read_yes_no_file.f,locked, try again,read =',ready
        go to 10
       end if

!       remove lock file
11     close (status='delete',unit=11,iostat=err_message)
        if (err_message.ne.0) then
         go to 11
!         print *, 'read_yes_no_file.f, err_messg=',err_message
        end if

      end subroutine read_yes_no_file
